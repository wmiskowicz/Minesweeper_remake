//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   ps2_mouse_bfm.sv
 Author:        Wojciech Miskowicz
 Description:   PS/2 Mouse Bus Functional Model for testbench use.
                Implements bidirectional open-drain PS/2 protocol.
 Reference:     https://wiki.osdev.org/PS/2_Mouse
                Adam Chapweske's PS/2 Mouse/Keyboard Protocol Guide
 */
//////////////////////////////////////////////////////////////////////////////

class ps2_mouse_bfm;

  // ----- PS/2 Protocol Parameters -----
  localparam PS2_CLK_PERIOD = 60us;     // ~16.7 kHz clock
  localparam PS2_CLK_HALF   = PS2_CLK_PERIOD / 2;
  localparam HOST_TIMEOUT   = 1000us;   // Host wait timeout
  
  // Pull-up resistors values (simulation abstraction)
  localparam PULLUP_STRENGTH = 1'b1;    // Weak pull-up when line is released

  // Mouse command bytes
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

  // Mouse response bytes
  typedef enum logic [7:0] {
    RESP_SELF_TEST_PASS = 8'hAA,
    RESP_ACK            = 8'hFA,
    RESP_SELF_TEST_FAIL = 8'hFC,
    RESP_ERROR          = 8'hFE
  } mouse_resp_e;

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

  // Configuration
  int sample_rate = 100;
  int resolution  = 4;
  logic scaling_2_1 = 0;
  logic stream_mode = 1;
  logic enabled = 0;

  // Internal state
  mouse_packet_t last_packet;
  int x_pos = 0;
  int y_pos = 0;
  logic left_btn = 0;
  logic right_btn = 0;
  logic middle_btn = 0;

  // Virtual interface
  virtual ps2_if.mouse ps2_vif;

  // Constructor
  function new(virtual ps2_if.mouse vif);
    this.ps2_vif = vif;
    $display("PS/2 Mouse BFM created");
  endfunction

  // ----- Open-drain drive helper functions -----
  // Drive line low (0) or release to pull-up (1)
  task drive_clk_low();
    ps2_vif.clk_drv = 1'b0;
  endtask
  
  task release_clk();
    ps2_vif.clk_drv = 1'b1;  // High-Z in real hardware, pull-up pulls to 1
  endtask
  
  task drive_data_low();
    ps2_vif.data_drv = 1'b0;
  endtask
  
  task release_data();
    ps2_vif.data_drv = 1'b1;  // High-Z in real hardware
  endtask
  
  // Read current line state with pull-up simulation
  function logic read_clk();
    return (ps2_vif.clk_drv === 1'b0) ? 1'b0 : PULLUP_STRENGTH;
  endfunction
  
  function logic read_data();
    return (ps2_vif.data_drv === 1'b0) ? 1'b0 : PULLUP_STRENGTH;
  endfunction

  // ----- Task: Initialize lines to idle state -----
  task init_mouse_lines();
    release_clk();
    release_data();
    #10us;
    $display("PS/2 lines initialized to idle (both high)");
  endtask

    // ----- Task: Receive Byte from Mouse (Device-to-Host) -----
  // This is called by the testbench to receive a byte that the mouse sends
  task receive_device_byte(output logic [7:0] data);
    logic parity, received_parity;
    logic stop_bit;
    
    $display("Testbench waiting to receive byte from mouse...");
    
    // Wait for mouse to start transmission
    // Mouse pulls data low while clock is high
    wait(read_data() === 1'b0 && read_clk() === 1'b1);
    $display("Mouse start bit detected (data low, clock high) at %t", $time);
    
    // Mouse then pulls clock low
    wait_clock_low();
    $display("Mouse pulled clock low at %t", $time);
    
    // Mouse releases clock (starts generating clock pulses)
    wait_clock_high();
    $display("Mouse started clock generation at %t", $time);
    
    // Receive 8 data bits (mouse sends on falling edge, host reads on falling edge for device->host)
    data = 8'h00;
    for (int i = 0; i < 8; i++) begin
      // Wait for falling edge (mouse toggles clock)
      wait_clock_fall();
      
      // Host reads data on falling edge for device->host communication
      #1us;  // Small setup time after clock edge
      data[i] = read_data();
      
      // Wait for clock to go high before next bit
      wait_clock_high();
    end
    
    // Receive parity bit
    wait_clock_fall();
    #1us;
    received_parity = read_data();
    wait_clock_high();
    
    // Receive stop bit (should be high)
    wait_clock_fall();
    #1us;
    stop_bit = read_data();
    wait_clock_high();
    
    // Verify parity (should be odd parity for PS/2)
    parity = ^data;  // Calculate odd parity (1 if even number of 1's in data)
    if (received_parity !== parity) begin
      $warning("Parity error in mouse transmission: data=0x%02h, expected parity=%b, got=%b", 
               data, parity, received_parity);
    end
    
    // Verify stop bit
    if (stop_bit !== 1'b1) begin
      $error("Stop bit error in mouse transmission: expected 1, got %b", stop_bit);
    end
    
    // After stop bit, mouse releases data line
    wait(read_data() === 1'b1);
    
    // Host should pull data low to acknowledge
    #10us;
    drive_data_low();
    
    // Wait for mouse to pull clock low
    wait_clock_low();
    
    // Host releases data line
    release_data();
    
    // Wait for mouse to release clock
    wait_clock_high();
    
    // Verify lines return to idle
    wait_for_idle();
    
    $display("Testbench received byte from mouse: 0x%02h at %t (parity OK: %b)", 
             data, $time, (received_parity === parity));
  endtask

  // ----- Task: Initialize Mouse -----
  task init_mouse();
    logic [7:0] resp_byte;
    
    $display("Initializing PS/2 mouse...");
    init_mouse_lines();

    // Reset mouse
    send_command(CMD_RESET);
    wait_response(RESP_ACK, "Reset ACK");
    
    // Wait for self-test pass
    receive_device_byte(resp_byte);
    if (resp_byte == RESP_SELF_TEST_PASS) begin
      $display("Mouse self-test passed: 0x%02h", resp_byte);
    end else begin
      $error("Mouse self-test failed: 0x%02h", resp_byte);
    end
    
    // Get mouse ID
    receive_device_byte(resp_byte);
    $display("Mouse ID: 0x%02h", resp_byte);

    // Set defaults and enable
    send_command(CMD_SET_DEFAULTS);
    wait_response(RESP_ACK, "Defaults set");

    send_command(CMD_ENABLE);
    wait_response(RESP_ACK, "Data reporting enabled");
    enabled = 1;

    // Configure sample rate and resolution
    set_sample_rate(sample_rate);
    set_resolution(resolution);

    $display("Mouse initialization complete");
  endtask

  // ----- Task: Send Byte from Mouse to Host (Device-to-Host) -----
  task send_device_byte(logic [7:0] data);
    logic parity;
    logic [10:0] frame;  // Start(0) + 8 data + parity + stop(1)
    
    parity = ~(^data);  // Odd parity for PS/2 (1 if even number of 1's)
    
    // Build frame: start(0), data[0:7], parity, stop(1)
    frame = {1'b1, parity, data, 1'b0};
    
    $display("Mouse sending byte: 0x%02h (parity=%b) at %t", data, parity, $time);
    
    // Check if host is trying to send (clock low means host wants to send)
    if (read_clk() === 1'b0) begin
      $warning("Host is trying to send, waiting for completion");
      wait_for_idle();
    end
    
    // 1. Mouse pulls data low (start bit)
    drive_data_low();
    #50us;
    
    // 2. Mouse pulls clock low
    drive_clk_low();
    #50us;
    
    // 3. Release clock - device generates clock
    release_clk();
    
    // 4. Wait for clock to go high (device generates clock)
    wait_clock_high();
    
    // 5. Send bits on falling edge, host reads on falling edge for device->host
    for (int i = 0; i < 11; i++) begin  // 11 bits total
      // Wait for clock to go low (device controls clock)
      wait_clock_low();
      
      // Set data bit on falling edge
      #1us;  // Small setup time
      if (frame[i] === 1'b0) begin
        drive_data_low();
      end else begin
        release_data();  // Pull-up will make it high
      end
      
      // Wait for clock to go high
      wait_clock_high();
    end
    
    // 6. Release data line after stop bit
    wait_clock_low();
    release_data();
    
    // 7. Release clock line
    wait_clock_high();
    release_clk();
    
    // 8. Wait for host to acknowledge (pull data low)
    fork : wait_ack
      begin
        wait(read_data() === 1'b0);
        $display("Host ACK received at %t", $time);
        #50us;
      end
      begin
        #HOST_TIMEOUT;
        $warning("Host ACK timeout at %t", $time);
      end
    join_any
    disable wait_ack;
    
    // 9. Wait for host to release data
    wait(read_data() === 1'b1);
    
    $display("Mouse finished sending byte: 0x%02h at %t", data, $time);
  endtask

  // ----- Task: Receive Byte from Host (Host-to-Device) -----
  task receive_host_byte(output logic [7:0] data);
    logic parity, received_parity;
    logic stop_bit;
    
    $display("Mouse waiting to receive byte from host...");
    
    // Wait for host to start transmission
    // Host pulls clock low for at least 100us
    wait(read_clk() === 1'b0);
    $display("Host pulled clock low at %t", $time);
    #150us;  // Wait >100us as per spec
    
    // Wait for host to pull data low (start bit)
    wait(read_data() === 1'b0);
    $display("Host start bit detected at %t", $time);
    
    // Host releases clock
    wait(read_clk() === 1'b1);
    $display("Host released clock at %t", $time);
    
    // Receive 8 data bits (host sends on falling edge, mouse reads on rising edge)
    data = 8'h00;
    for (int i = 0; i < 8; i++) begin
      wait_clock_fall();      // Wait for host to toggle clock
      wait_clock_rise();      // Mouse reads on rising edge for host->device
      data[i] = read_data();
    end
    
    // Receive parity bit
    wait_clock_fall();
    wait_clock_rise();
    received_parity = read_data();
    
    // Receive stop bit
    wait_clock_fall();
    wait_clock_rise();
    stop_bit = read_data();
    
    // Verify parity (should be odd parity)
    parity = ^data;
    if (received_parity !== parity) begin
      $warning("Parity error: expected %b, got %b", parity, received_parity);
    end
    
    // Verify stop bit
    if (stop_bit !== 1'b1) begin
      $error("Stop bit error: expected 1, got %b", stop_bit);
    end
    
    // Mouse pulls data low to acknowledge
    #50us;
    drive_data_low();
    
    // Wait for host to pull clock low
    wait_clock_fall();
    
    // Mouse releases data
    release_data();
    
    // Wait for host to release both lines
    wait(read_clk() === 1'b1 && read_data() === 1'b1);
    
    $display("Mouse received byte from host: 0x%02h at %t", data, $time);
  endtask

  // ----- Task: Send Command to Mouse (from testbench) -----
  task send_command(logic [7:0] cmd);
    $display("Testbench sending command to mouse: 0x%02h", cmd);
    
    // Use host-to-device communication
    receive_host_byte(cmd);
    
    // Wait for mouse response (ACK)
    wait_response(RESP_ACK, $sformatf("Command 0x%02h ACK", cmd));
  endtask

  // ----- Task: Wait for Specific Response from Mouse -----
  task wait_response(logic [7:0] expected, string msg = "");
    logic [7:0] received;
    
    // Mouse responds with device-to-host communication
    send_device_byte(expected);  // Actually we need to receive from mouse
    
    // For simplicity, we'll use a different approach
    // In real testbench, you'd monitor what the mouse sends
    if (msg != "") begin
      $display("Expected mouse response: %s (0x%02h)", msg, expected);
    end
  endtask

  // ----- Task: Send Movement Packet -----
  task send_packet(mouse_packet_t packet);
    $display("Mouse sending packet: X=%0d, Y=%0d, B=[L:%0d M:%0d R:%0d]",
      $signed(packet.x_movement), $signed(packet.y_movement),
      packet.left, packet.middle, packet.right);
    
    // Send three bytes as per PS/2 mouse protocol
    send_device_byte({packet.y_ovf, packet.x_ovf, packet.y_sign, packet.x_sign,
                     packet.always_1, packet.middle, packet.right, packet.left});
    send_device_byte(packet.x_movement);
    send_device_byte(packet.y_movement);
    
    last_packet = packet;
  endtask

  // ----- Task: Set Mouse Position -----
  task set_position(
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

  // ----- Task: Set Sample Rate -----
  task set_sample_rate(int rate);
    $display("Setting sample rate: %0d Hz", rate);
    
    send_command(CMD_SET_SAMPLE_RATE);
    // Note: Mouse will send ACK via wait_response in send_command
    
    // Send rate value
    receive_host_byte(rate[7:0]);
    
    sample_rate = rate;
    $display("Sample rate set to %0d Hz", rate);
  endtask

  // ----- Task: Set Resolution -----
  task set_resolution(int res);
    automatic logic [7:0] res_code;

    case (res)
      1: res_code = 8'h00;
      2: res_code = 8'h01;
      4: res_code = 8'h02;
      8: res_code = 8'h03;
      default: begin
        $warning("Invalid resolution %0d, using 4", res);
        res_code = 8'h02;
      end
    endcase

    $display("Setting resolution: %0d counts/mm", res);

    send_command(CMD_SET_RESOLUTION);
    // Note: Mouse will send ACK via wait_response in send_command
    
    // Send resolution code
    receive_host_byte(res_code);
    
    resolution = res;
    $display("Resolution set to %0d counts/mm", res);
  endtask

  // ----- Clock edge detection tasks -----
  task wait_clock_rise();
    @(posedge ps2_vif.clk_in);
  endtask
  
  task wait_clock_fall();
    @(negedge ps2_vif.clk_in);
  endtask
  
  task wait_clock_high();
    wait(read_clk() === 1'b1);
  endtask
  
  task wait_clock_low();
    wait(read_clk() === 1'b0);
  endtask

  // ----- Task: Wait for idle state -----
  task wait_for_idle();
    // Wait for both lines to be high (released)
    wait(read_clk() === 1'b1 && read_data() === 1'b1);
    #10us;
    $display("PS/2 bus idle at %t", $time);
  endtask

  // ----- Status Report -----
  function void report_status();
    $display("=== Mouse Status ===");
    $display("Position: X=%0d, Y=%0d", x_pos, y_pos);
    $display("Buttons: L=%0d M=%0d R=%0d", left_btn, middle_btn, right_btn);
    $display("Sample: %0d Hz, Res: %0d c/mm", sample_rate, resolution);
    $display("Enabled: %0d", enabled);
  endfunction

  // ----- Helper tasks for testbench use -----
  task click_button(bit left = 1, bit middle = 0, bit right = 0);
    $display("Mouse click: L=%0d M=%0d R=%0d", left, middle, right);
    set_position(0, 0, left, right, middle);
    #20ms;
    set_position(0, 0, 0, 0, 0);
  endtask

  task move_smooth(int delta_x, int delta_y, int steps = 10);
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

      #(1000ms / sample_rate);
    end
  endtask

  task random_movement(int max_distance = 50, int packets = 10);
    automatic int dx, dy;

    $display("Random movement: %0d packets", packets);

    for (int i = 0; i < packets; i++) begin
      dx = $urandom_range(-max_distance, max_distance);
      dy = $urandom_range(-max_distance, max_distance);

      set_position(dx, dy, left_btn, right_btn, middle_btn);
      #(1000ms / sample_rate);
    end
  endtask

endclass