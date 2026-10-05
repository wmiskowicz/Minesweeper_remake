//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   ps2_mouse_bfm.sv
 Author:        Wojciech Miskowicz
 Description:   PS/2 Mouse Bus Functional Model for testbench use.
                Implements the bidirectional open-drain PS/2 protocol,
                acting as the device side of the link (the host is the DUT).

                In the real protocol, the DEVICE always generates the
                clock square wave on ps2_clk, even for host-to-device
                transfers: the host merely requests a transfer by
                holding the clock low, then lets the device clock the
                bits in. This model reflects that: every byte transfer,
                in either direction, is driven by this BFM toggling
                clk_drv itself.

                A single background process (bus_owner) owns the bus.
                It answers whatever the host (DUT) sends (ACK, BAT result,
                device ID) and, whenever the host is quiet, transmits the
                movement packets queued by the testbench API
                (set_position, click_button, ...). Having one owner
                guarantees the BFM never mistakes its own clock pulses
                for a host request-to-send, and never interleaves a
                command response with a movement packet.
 Reference:     https://wiki.osdev.org/PS/2_Mouse
                Adam Chapweske's PS/2 Mouse/Keyboard Protocol Guide
 */
//////////////////////////////////////////////////////////////////////////////

class ps2_mouse_bfm;

  // ----- PS/2 Protocol Parameters -----
  // A real mouse clocks at 10-16.7kHz (60-100us period). The DUT
  // (Ps2Interface.vhd) has no upper bound on the bit time and only needs
  // each level to be stable for >16 cycles @100MHz to pass its
  // debouncer, so the period can be shortened to speed up simulation.
  // Keep it well above ~1us so every level survives the debouncer and
  // the host's 63-cycle wait after releasing the clock.
  realtime clk_half_period;

  // A real mouse is a free-running oscillator, completely async to the
  // FPGA's 100MHz system clock. Jitter each half-period slightly so the
  // edges don't always land at the same phase of the system clock.
  function automatic realtime half_period_jittered();
    return clk_half_period + ($urandom_range(0, 19) * 1ns);
  endfunction

  // Mouse command bytes (sent by host)
  typedef enum logic [7:0] {
    CMD_RESET           = 8'hFF,
    CMD_RESEND          = 8'hFE,
    CMD_SET_DEFAULTS    = 8'hF6,
    CMD_DISABLE         = 8'hF5,
    CMD_ENABLE          = 8'hF4,
    CMD_SET_SAMPLE_RATE = 8'hF3,
    CMD_GET_DEVICE_ID   = 8'hF2,
    CMD_SET_REMOTE_MODE = 8'hF0,
    CMD_SET_WRAP_MODE   = 8'hEE,
    CMD_RESET_WRAP_MODE = 8'hEC,
    CMD_READ_DATA       = 8'hEB,
    CMD_SET_STREAM_MODE = 8'hEA,
    CMD_STATUS_REQUEST  = 8'hE9,
    CMD_SET_RESOLUTION  = 8'hE8,
    CMD_SET_SCALING_2_1 = 8'hE7,
    CMD_SET_SCALING_1_1 = 8'hE6
  } mouse_cmd_e;

  // Mouse response bytes (sent by device)
  typedef enum logic [7:0] {
    RESP_SELF_TEST_PASS = 8'hAA,
    RESP_ACK            = 8'hFA,
    RESP_SELF_TEST_FAIL = 8'hFC,
    RESP_ERROR          = 8'hFE
  } mouse_resp_e;

  localparam logic [7:0] MOUSE_ID = 8'h00; // plain 3-byte-packet mouse, no wheel

  // Mouse packet structure
  typedef struct packed {
    logic       y_ovf;
    logic       x_ovf;
    logic       y_sign;
    logic       x_sign;
    logic       always_1;
    logic       middle;
    logic       right;
    logic       left;
    logic [7:0] x_movement;
    logic [7:0] y_movement;
  } mouse_packet_t;

  // Internal state
  int x_pos = 0;
  int y_pos = 0;
  logic left_btn   = 0;
  logic right_btn  = 0;
  logic middle_btn = 0;
  bit   enabled    = 0;
  bit   verbose    = 1;

  // Set when the previous host byte was a command that takes a
  // parameter (SET_SAMPLE_RATE, SET_RESOLUTION): the next byte is that
  // parameter and must only be ACKed, never decoded as a command.
  bit expect_param = 0;

  // Bytes waiting to be sent to the host (movement packets), and the
  // number of bytes the bus owner is still transmitting from it.
  logic [7:0] tx_queue[$];
  bit         tx_busy = 0;

  // Fires each time the host (DUT) finishes a full init handshake and
  // sends CMD_ENABLE, i.e. once the mouse is ready to stream movement.
  event e_init_done;

  // Virtual interface
  virtual ps2_if.mouse ps2_vif;

  // Constructor
  function new(virtual ps2_if.mouse vif, realtime half_period = 30us);
    this.ps2_vif = vif;
    this.clk_half_period = half_period;
    $display("PS/2 Mouse BFM created (clock half-period %0t)", half_period);
  endfunction

  // ----- Open-drain drive helper tasks -----
  task drive_clk_low();
    ps2_vif.clk_drv = 1'b0;
  endtask

  task release_clk();
    ps2_vif.clk_drv = 1'b1;
  endtask

  task drive_data_low();
    ps2_vif.data_drv = 1'b0;
  endtask

  task release_data();
    ps2_vif.data_drv = 1'b1;
  endtask

  // Read the actual bus line state (resolution of every driver)
  function logic read_data();
    return ps2_vif.data_in;
  endfunction

  // ----- Task: start the BFM -----
  // Releases both lines and launches the background bus owner that
  // keeps answering the host for the rest of the simulation. Call this
  // once, before the DUT is taken out of reset.
  task automatic start();
    release_clk();
    release_data();
    #10us;
    $display("PS/2 lines initialized to idle (both high)");
    fork
      bus_owner();
    join_none
  endtask

  // ----- Task: wait for the host to complete its init sequence -----
  // The DUT re-runs its whole RESET..ENABLE handshake every time it is
  // reset, so this can be called again after every reset.
  task automatic init_mouse();
    $display("Waiting for host to complete mouse initialization...");
    @(e_init_done);
    $display("Mouse initialization complete at %t", $time);
  endtask

  // ----- Background task: the only process that touches the bus -----
  // Host requests always win: a host request-to-send (clock pulled low
  // while we are not driving it) is served first. Queued movement bytes
  // are only sent while the host is idle and the mouse is enabled.
  task automatic bus_owner();
    logic [7:0] cmd;
    forever begin
      // Host request-to-send: clock low while we are not driving it.
      if (ps2_vif.clk_in === 1'b0 && ps2_vif.clk_drv === 1'b1) begin
        receive_host_byte(cmd);
        handle_host_byte(cmd);
      end else if (enabled && tx_queue.size() > 0) begin
        tx_busy = 1;
        send_device_byte(tx_queue.pop_front());
        tx_busy = 0;
      end else begin
        // Poll: a host request-to-send holds the clock low for 100us,
        // so a 1us poll can't miss it, and it also picks up bytes newly
        // queued by the testbench.
        #1us;
      end
    end
  endtask

  // ----- Protocol behaviour for each byte received from the host -----
  task automatic handle_host_byte(logic [7:0] cmd);
    if (expect_param) begin
      // Parameter of SET_SAMPLE_RATE / SET_RESOLUTION
      expect_param = 0;
      send_device_byte(RESP_ACK);
      return;
    end

    case (cmd)
      CMD_RESET: begin
        enabled = 0;
        tx_queue.delete();
        send_device_byte(RESP_ACK);
        send_device_byte(RESP_SELF_TEST_PASS);
        send_device_byte(MOUSE_ID);
      end

      CMD_GET_DEVICE_ID: begin
        send_device_byte(RESP_ACK);
        send_device_byte(MOUSE_ID);
      end

      CMD_SET_SAMPLE_RATE, CMD_SET_RESOLUTION: begin
        expect_param = 1;
        send_device_byte(RESP_ACK);
      end

      CMD_ENABLE: begin
        send_device_byte(RESP_ACK);
        enabled = 1;
        -> e_init_done;
      end

      CMD_DISABLE: begin
        send_device_byte(RESP_ACK);
        enabled = 0;
      end

      default: begin
        // SET_DEFAULTS, SET_SCALING, ... : a plain ACK.
        send_device_byte(RESP_ACK);
      end
    endcase
  endtask

  // ----- Task: Send Byte from Mouse to Host (Device-to-Host) -----
  // Device-generated clock: 11 pulses (start, 8 data bits, parity,
  // stop). Data is changed while the clock is high and sampled by the
  // host on the falling edge, per the PS/2 spec. No ack is expected
  // from the host for this direction.
  task automatic send_device_byte(logic [7:0] data);
    logic parity;
    logic [10:0] frame;  // {stop, parity, data[7:0], start}

    parity = ~(^data);  // odd parity
    frame = {1'b1, parity, data, 1'b0};

    wait_for_idle();
    if (verbose) $display("[%0t] BFM -> host: 0x%02h", $time, data);

    for (int i = 0; i < 11; i++) begin
      if (frame[i]) release_data();
      else          drive_data_low();
      #(half_period_jittered());
      drive_clk_low();   // falling edge: host samples data now
      #(half_period_jittered());
      release_clk();     // rising edge
    end

    release_data();
    settle();
  endtask

  // Let the bus resolve after we release the lines. Without this the
  // bus owner could re-sample clk_in in the same time step, still see
  // our own (stale) low level and mistake it for a host request-to-send.
  task automatic settle();
    #1us;
  endtask

  // ----- Task: Receive Byte from Host (Host-to-Device) -----
  // Host requests a transfer by holding clk low (>=100us) then data
  // low (start bit) then releasing clk. From there the DEVICE (us)
  // generates the clock: 8 data bits, parity and stop are read while
  // the clock is high (host changes data while it is low). An 11th
  // clock pulse carries our ACK (data held low).
  task automatic receive_host_byte(output logic [7:0] data);
    logic parity, received_parity, stop_bit;

    // Host is holding the clock low (>=100us). It then pulls data low
    // (start bit) and finally releases the clock: only then may we
    // start clocking the bits in.
    wait (ps2_vif.data_in === 1'b0);
    wait (ps2_vif.clk_in === 1'b1);
    #(half_period_jittered());

    data = 8'h00;
    for (int i = 0; i < 10; i++) begin
      drive_clk_low();
      #(half_period_jittered());
      release_clk();
      #(half_period_jittered());
      if (i < 8)
        data[i] = read_data();
      else if (i == 8)
        received_parity = read_data();
      else
        stop_bit = read_data();
    end

    parity = ~(^data);  // odd parity, matching send_device_byte
    if (received_parity !== parity)
      $error("Parity error in host->device transmission: data=0x%02h, expected parity=%b, got=%b",
             data, parity, received_parity);
    if (stop_bit !== 1'b1)
      $error("Stop bit error in host->device transmission: expected 1, got %b", stop_bit);

    // Acknowledge: data low, then one more clock pulse, then release.
    drive_data_low();
    #(half_period_jittered());
    drive_clk_low();
    #(half_period_jittered());
    release_clk();
    release_data();
    settle();

    if (verbose) $display("[%0t] host -> BFM: 0x%02h", $time, data);
  endtask

  // ----- Task: Send Movement Packet -----
  // Queues the 3 packet bytes for the bus owner and blocks until they
  // have all been transmitted.
  task automatic send_packet(mouse_packet_t packet);
    $display("Mouse sending packet: X=%0d, Y=%0d, B=[L:%0d M:%0d R:%0d]",
      $signed(packet.x_movement), $signed(packet.y_movement),
      packet.left, packet.middle, packet.right);

    if (!enabled)
      $warning("Packet queued while mouse reporting is disabled; it is held until the host enables it");

    tx_queue.push_back({packet.y_ovf, packet.x_ovf, packet.y_sign, packet.x_sign,
                        packet.always_1, packet.middle, packet.right, packet.left});
    tx_queue.push_back(packet.x_movement);
    tx_queue.push_back(packet.y_movement);
    wait (tx_queue.size() == 0 && !tx_busy);
  endtask

  // ----- Task: Set Mouse Position (relative move + button state) -----
  task automatic set_position(
    input int delta_x,
    input int delta_y,
    logic left = 0,
    logic right = 0,
    logic middle = 0);

    automatic mouse_packet_t packet;
    automatic logic signed [7:0] dx_signed, dy_signed;

    left_btn = left;
    right_btn = right;
    middle_btn = middle;

    x_pos += delta_x;
    y_pos += delta_y;

    // Convert to signed 8-bit with saturation
    if (delta_x > 127) begin
      dx_signed = 8'd127;
      packet.x_ovf = 1'b1;
    end else if (delta_x < -128) begin
      dx_signed = -8'd128;
      packet.x_ovf = 1'b1;
    end else begin
      dx_signed = delta_x;
      packet.x_ovf = 1'b0;
    end

    if (delta_y > 127) begin
      dy_signed = 8'd127;
      packet.y_ovf = 1'b1;
    end else if (delta_y < -128) begin
      dy_signed = -8'd128;
      packet.y_ovf = 1'b1;
    end else begin
      dy_signed = delta_y;
      packet.y_ovf = 1'b0;
    end

    packet.left = left_btn;
    packet.right = right_btn;
    packet.middle = middle_btn;
    packet.always_1 = 1'b1;
    packet.x_sign = dx_signed[7];
    packet.y_sign = dy_signed[7];
    packet.x_movement = dx_signed;
    packet.y_movement = dy_signed;

    send_packet(packet);
  endtask

  // ----- Task: Wait for idle state -----
  task automatic wait_for_idle();
    wait (ps2_vif.clk_in === 1'b1 && ps2_vif.data_in === 1'b1);
    #(half_period_jittered());
  endtask

  // ----- Status Report -----
  function void report_status();
    $display("=== Mouse Status ===");
    $display("Position: X=%0d, Y=%0d", x_pos, y_pos);
    $display("Buttons: L=%0d M=%0d R=%0d", left_btn, middle_btn, right_btn);
    $display("Enabled: %0d", enabled);
  endfunction

  // ----- Helper tasks for testbench use -----
  task automatic click_button(bit left = 1, bit middle = 0, bit right = 0);
    $display("Mouse click: L=%0d M=%0d R=%0d", left, middle, right);
    set_position(0, 0, left, right, middle);
    // Held just long enough to clear the CDC/FIFO pipeline into
    // mouse_xpos/left/right, not a realistic human click duration.
    #200us;
    set_position(0, 0, 0, 0, 0);
  endtask

  task automatic move_smooth(int delta_x, int delta_y, int steps = 10);
    automatic int step_x, step_y;
    automatic int current_x = 0;
    automatic int current_y = 0;

    $display("Smooth move: dx=%0d, dy=%0d in %0d steps", delta_x, delta_y, steps);

    for (int i = 1; i <= steps; i++) begin
      step_x = (delta_x * i / steps) - current_x;
      step_y = (delta_y * i / steps) - current_y;

      set_position(step_x, step_y, left_btn, right_btn, middle_btn);

      current_x += step_x;
      current_y += step_y;
    end
  endtask

  task automatic random_movement(int max_distance = 50, int packets = 10);
    automatic int dx, dy;

    $display("Random movement: %0d packets", packets);

    for (int i = 0; i < packets; i++) begin
      dx = $urandom_range(-max_distance, max_distance);
      dy = $urandom_range(-max_distance, max_distance);

      set_position(dx, dy, left_btn, right_btn, middle_btn);
    end
  endtask

endclass
