//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   ps2_mouse_bfm.sv
 Author:        Wojciech Miskowicz
 Description:   PS/2 Mouse Bus Functional Model for testbench use.
                Implements bidirectional open-drain PS/2 protocol.
 Reference:     https://wiki.osdev.org/PS/2_Mouse
 */
//////////////////////////////////////////////////////////////////////////////
`include "ps2_if.sv"

class ps2_mouse_bfm;

  // ----- PS/2 Protocol Parameters -----
  localparam PS2_CLK_PERIOD = 60us; // PS/2 clock period (16.7 kHz typical)
  localparam PS2_CLK_HALF   = PS2_CLK_PERIOD / 2;

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
  virtual ps2_if.master ps2_vif;

  // Constructor
  function new(virtual ps2_if.master vif);
    this.ps2_vif = vif;
    $display("PS/2 Mouse BFM created");
  endfunction

  // Initialize lines to idle state (high) - MUST be a separate task
  task initialize_lines();
    ps2_vif.clk_drive = 1'b1;
    ps2_vif.data_drive = 1'b1;
    #1us;
  endtask

  // ----- Task: Initialize Mouse -----
  task init_mouse();
    logic [7:0] resp_byte;
    
    $display("Initializing PS/2 mouse...");

    send_command(CMD_RESET);
    wait_response(RESP_SELF_TEST_PASS, "Self-test passed");
    
    receive_byte(resp_byte);  // Mouse ID byte
    if (resp_byte == 8'h00) begin
      $display("Mouse ID: 0x%02h (standard mouse)", resp_byte);
    end

    send_command(CMD_SET_DEFAULTS);
    wait_response(RESP_ACK, "Defaults set");

    send_command(CMD_ENABLE);
    wait_response(RESP_ACK, "Data reporting enabled");
    enabled = 1;

    set_sample_rate(sample_rate);
    set_resolution(resolution);

    $display("Mouse initialization complete");
  endtask

  // ----- Task: Set Mouse Position -----
  task set_position(
    input int delta_x, 
    input int delta_y,
    logic left = 0, 
    logic right = 0, 
    logic middle = 0);
    
    automatic mouse_packet_t packet;

    left_btn = left;
    right_btn = right;
    middle_btn = middle;

    x_pos += delta_x;
    y_pos += delta_y;

    // Clamp to 8-bit signed range
    if (delta_x > 127) delta_x = 127;
    if (delta_x < -128) delta_x = -128;
    if (delta_y > 127) delta_y = 127;
    if (delta_y < -128) delta_y = -128;

    packet.left = left_btn;
    packet.right = right_btn;
    packet.middle = middle_btn;
    packet.always_1 = 1'b1;
    packet.x_sign = (delta_x < 0);
    packet.y_sign = (delta_y < 0);
    packet.x_ovf = 0; // No overflow for normal movements
    packet.y_ovf = 0;
    packet.x_movement = delta_x[7:0];
    packet.y_movement = delta_y[7:0];

    send_packet(packet);

    $display("Mouse: dx=%0d, dy=%0d, B=[L:%0d M:%0d R:%0d]",
      delta_x, delta_y, left_btn, middle_btn, right_btn);
  endtask

  // ----- Task: Click Mouse Button -----
  task click_button(bit left = 1, bit middle = 0, bit right = 0);
    $display("Mouse click: L=%0d M=%0d R=%0d", left, middle, right);

    set_position(0, 0, left, right, middle);
    #100ms;
    set_position(0, 0, 0, 0, 0);
  endtask

  // ----- Task: Move Mouse Smoothly -----
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

  // ----- Task: Send Command to Mouse -----
  task send_command(logic [7:0] cmd);
    $display("Mouse command: 0x%02h", cmd);

    send_byte(cmd);

    // Wait for transmission to complete
    #100us;
  endtask

  // ----- Task: Send Movement Packet -----
  task send_packet(mouse_packet_t packet);
    $display("Mouse packet: X=%0d, Y=%0d",
      $signed(packet.x_movement), $signed(packet.y_movement));

    send_byte({packet.y_ovf, packet.x_ovf, packet.y_sign, packet.x_sign,
      packet.always_1, packet.middle, packet.right, packet.left});
    send_byte(packet.x_movement);
    send_byte(packet.y_movement);

    last_packet = packet;
  endtask

  // ----- Task: Send Byte (Mouse to Host) -----
  task send_byte(logic [7:0] data);
    automatic logic parity;

    parity = ^data; // Odd parity

    // Wait for clock idle (high)
    wait_for_idle();

    // Mouse starts transmission by pulling data low
    ps2_vif.data_drive = 1'b0;
    wait_for_clock_high();
    #PS2_CLK_HALF;

    // Send 8 data bits
    for (int i = 0; i < 8; i++) begin
      wait_for_clock_fall();
      ps2_vif.data_drive = data[i];
      #PS2_CLK_HALF;
    end

    // Send parity bit
    wait_for_clock_fall();
    ps2_vif.data_drive = parity;
    #PS2_CLK_HALF;

    // Send stop bit
    wait_for_clock_fall();
    ps2_vif.data_drive = 1'b1;
    #PS2_CLK_HALF;

    // Wait for host to pull clock low to acknowledge
    wait_for_clock_fall();
    #PS2_CLK_HALF;

    // Release data line
    ps2_vif.data_drive = 1'b1;
  endtask

  // ----- Task: Wait for Specific Response -----
  task wait_response(logic [7:0] expected, string msg = "");
    automatic logic [7:0] received;

    receive_byte(received);

    if (received == expected) begin
      if (msg != "") $display("Mouse response: %s (0x%02h)", msg, received);
    end else begin
      $error("Mouse: Expected 0x%02h, got 0x%02h", expected, received);
    end
  endtask

  // ----- Task: Receive Byte from Host -----
  task receive_byte(output logic [7:0] data);
    automatic logic parity;

    data = 0;

    // Host initiates by pulling clock low
    wait_for_clock_low();

    // Host pulls data low for start bit
    while (ps2_vif.data_in != 1'b0) @(posedge ps2_vif.clk_in);

    // Wait for clock to be released
    wait_for_clock_high();

    // Sample 8 data bits on falling edges
    for (int i = 0; i < 8; i++) begin
      wait_for_clock_fall();
      data[i] = ps2_vif.data_in;
    end

    // Sample parity
    wait_for_clock_fall();
    parity = ps2_vif.data_in;

    // Sample stop bit
    wait_for_clock_fall();

    // Mouse pulls data low to acknowledge
    ps2_vif.data_drive = 1'b0;
    #50us;
    ps2_vif.data_drive = 1'b1;

    $display("Mouse received: 0x%02h (parity=%0d)", data, parity);
  endtask

  // ----- Task: Set Sample Rate -----
  task set_sample_rate(int rate);
    $display("Setting sample rate: %0d Hz", rate);

    send_command(CMD_SET_SAMPLE_RATE);
    wait_response(RESP_ACK, "Sample rate command ACK");

    send_byte(rate);
    wait_response(RESP_ACK, "Sample rate set");

    sample_rate = rate;
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
    wait_response(RESP_ACK, "Resolution command ACK");

    send_byte(res_code);
    wait_response(RESP_ACK, "Resolution set");

    resolution = res;
  endtask

  // ----- Helper Tasks -----
  task wait_for_idle();
    // Wait for clock and data to be high
    while (!(ps2_vif.clk_in === 1'b1 && ps2_vif.data_in === 1'b1)) begin
      #1us;
    end
    #10us;
  endtask

  task wait_for_clock_high();
    @(posedge ps2_vif.clk_in);
  endtask

  task wait_for_clock_low();
    @(negedge ps2_vif.clk_in);
  endtask

  task wait_for_clock_fall();
    @(negedge ps2_vif.clk_in);
  endtask

  // ----- Status Report -----
  function void report_status();
    $display("=== Mouse Status ===");
    $display("Position: X=%0d, Y=%0d", x_pos, y_pos);
    $display("Buttons: L=%0d M=%0d R=%0d", left_btn, middle_btn, right_btn);
    $display("Sample: %0d Hz, Res: %0d c/mm", sample_rate, resolution);
  endfunction

  // ----- Random Movement -----
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