`include "constants.v"
module controller(
    input wire clk,
    input wire rst_n,
    input wire [31:0] instr,
    // grf
    output reg ctrl_grf_we,
    output reg ctrl_grf_wd_src,
    output reg [1:0] ctrl_grf_wa_src,
    output reg [4:0] grf_write_addr,
    // dm
    output reg ctrl_dm_we,
    output reg [1:0] ctrl_dm_width,
    output reg ctrl_dm_extend,
    // alu
    output reg [3:0] ctrl_alu_func,
    output reg ctrl_alu_in_a_src,
    output reg [1:0] ctrl_alu_in_b_src,
    // branch
    output reg ctrl_branch,
    // jump
    output reg [1:0] ctrl_jump,
    // imm mux
    output reg [1:0] ctrl_imm_src,
    // mul
    output reg [3:0] ctrl_mul_func,
    output reg [1:0] ctrl_alu_out_src,
    // cmp
    output reg [2:0] ctrl_cmp_func
    );
wire [5:0] op = instr[`op];
wire [4:0] rs = instr[`rs];
wire [4:0] rd = instr[`rd];
wire [4:0] rt = instr[`rt];
wire [5:0] funct = instr[`funct];
// op code
localparam special  = 0; // set collection
localparam regimm   = 1; // set collection
localparam j    = 2;
localparam jal  = 3;
localparam beq  = 4;
localparam bne  = 5;
localparam blez = 6;
localparam bgtz = 7;
localparam addi = 8;
localparam addiu= 9;
localparam slti = 10;
localparam sltiu= 11;
localparam andi = 12;
localparam ori  = 13;
localparam xori = 14;
localparam lui  = 15;
localparam cop0     = 16; // set collection
localparam special2 = 28; // set collection
localparam lb   = 32;
localparam lh   = 33;
localparam lwl  = 34; // not yet implemented
localparam lw   = 35;
localparam lbu  = 36;
localparam lhu  = 37;
localparam lwr  = 38; // not yet implemented
localparam sb   = 40;
localparam sh   = 41;
localparam swl  = 42; // not yet implemented
localparam sw   = 43;
localparam swr  = 46; // not yet implemented

// R type instr. funct
localparam sll     = 0;
localparam srl     = 2;
localparam sra     = 3;
localparam sllv    = 4;
localparam srlv    = 6;
localparam srav    = 7;
localparam jr      = 8;
localparam jalr    = 9;
localparam syscall = 12;
localparam mfhi    = 16;
localparam mthi    = 17;
localparam mflo    = 18;
localparam mtlo    = 19;
localparam mult    = 24;
localparam multu   = 25;
localparam div     = 26;
localparam divu    = 27;
localparam add     = 32;
localparam addu    = 33;
localparam sub     = 34;
localparam subu    = 35;
localparam _and    = 36;
localparam _or     = 37;
localparam _xor    = 38;
localparam _nor    = 39;
localparam slt     = 42;
localparam sltu    = 43;
// funct for special2
localparam madd  = 0;
localparam maddu = 1;
localparam mul   = 2;
localparam msub  = 4;
localparam msubu = 5;

// rs for cop0
localparam mfcz = 0;
localparam mtcz = 4;
localparam copz = 16;

// funct for cp0
localparam eret = 24;
// rt for regimm
localparam bltz = 0;
localparam bgez = 1;

`define writeBackfromALU \
    ctrl_grf_we = 1; \
    ctrl_grf_wd_src = `fromALU;

`define writeBackfromMem \
    ctrl_grf_we = 1; \
    ctrl_grf_wd_src = `fromDm;

// Data path macro
`define grfALU \
    ctrl_alu_in_b_src = `fromGrfRt; \
    `writeBackfromALU \
    ctrl_grf_wa_src = `toGrfRd;

`define grfALUShift \
    ctrl_alu_in_a_src = `fromGrfRt; \
    ctrl_alu_in_b_src = `fromShamt; \
    `writeBackfromALU \
    ctrl_grf_wa_src = `toGrfRd;

`define grfALUShiftVarible \
    ctrl_alu_in_a_src = `fromGrfRt; \
    ctrl_alu_in_b_src = `fromGrfRs; \
    `writeBackfromALU \
    ctrl_grf_wa_src = `toGrfRd;

`define immALU \
    ctrl_alu_in_b_src = `fromImm; \
    `writeBackfromALU \
    ctrl_grf_wa_src = `toGrfRt;

`define grfAcc \
    ctrl_alu_in_b_src = `fromGrfRt; \
    ctrl_grf_we = 0;

`define accGrf \
    `writeBackfromALU \
    ctrl_grf_wa_src = `toGrfRd;

`define branch \
    ctrl_branch = 1;

`define loadMemToRegRd \
    ctrl_alu_func = `aluAdd; \
    ctrl_alu_in_b_src = `fromImm; \
    `writeBackfromMem \
    ctrl_grf_wa_src = `toGrfRt;

`define storeRegRtTOMem \
    ctrl_alu_func = `aluAdd; \
    ctrl_alu_in_b_src = `fromImm; \
    ctrl_dm_we = 1;

`define jumpAndSavePC \
    ctrl_imm_src = `fromPC; \
    ctrl_alu_out_src =`directImm; \
    ctrl_grf_wd_src = `fromALU; \
    ctrl_grf_we = 1;

reg unknownInstr;
always @(*) begin
    unknownInstr = 0;
    // grf
    ctrl_grf_we = 0;
    ctrl_grf_wd_src = `fromALU;
    ctrl_grf_wa_src = `toGrfRd;
    // alu
    ctrl_alu_func = `aluDisable;
    ctrl_alu_in_a_src = `fromGrfRs;
    ctrl_alu_in_b_src = `fromGrfRt;
    // dm
    ctrl_dm_we = 0;
    ctrl_dm_width = `dmWidth4;
    ctrl_dm_extend = `signExt;
    // branch
    ctrl_branch = 0;
    // jump
    ctrl_jump = `jumpDisable;
    // imm mux 
    ctrl_imm_src = `signExt;
    // mul
    ctrl_mul_func = `mulDisable;
    ctrl_alu_out_src = `fromALUOut;
    // cmp
    ctrl_cmp_func = `cmpEqual;
    case (op)
        // r type
        special: begin
            case (funct)
                // Shift with imm:s 
                syscall: begin
                    $display("Syscall\n");
                    $finish();
                end
                sll: begin 
                    if (rd != 0 || rt != 0) begin
                       `grfALUShift
                        ctrl_alu_func = `aluSL; 
                    end
                end
                srl:begin 
                    `grfALUShift
                    ctrl_alu_func = `aluSR;
                end
                sra:begin 
                    `grfALUShift
                    ctrl_alu_func = `aluSRA;
                end
                // Shift Grf
                sllv: begin
                    `grfALUShiftVarible
                    ctrl_alu_func = `aluSL;
                end
                srlv: begin
                    `grfALUShiftVarible
                    ctrl_alu_func = `aluSR;
                end
                srav: begin
                    `grfALUShiftVarible
                    ctrl_alu_func = `aluSRA;
                end
                // A & L Grf
                add: begin
                    `grfALU
                    ctrl_alu_func = `aluAdd;
                    // overflow 
                end
                addu: begin
                    `grfALU
                    ctrl_alu_func = `aluAdd;
                end
                sub: begin
                    `grfALU
                    ctrl_alu_func = `aluSub;
                    // overflow 
                end
                subu: begin
                    `grfALU
                    ctrl_alu_func = `aluSub;
                end
                _and: begin
                    `grfALU
                    ctrl_alu_func = `aluAnd;
                end
                _or: begin
                    `grfALU
                    ctrl_alu_func = `aluOr;
                end
                _xor: begin
                    `grfALU
                    ctrl_alu_func = `aluXor;
                end
                _nor: begin
                    `grfALU
                    ctrl_alu_func = `aluNor;
                end
                // Set Grf
                slt: begin 
                    `grfALU
                    ctrl_alu_func = `aluSLT;
                end
                sltu: begin 
                    `grfALU
                    ctrl_alu_func = `aluSLTU;
                end
                // Multiplier Grf
                mult: begin
                    `grfAcc
                    ctrl_mul_func = `mulMULT;
                end
                multu: begin
                    `grfAcc
                    ctrl_mul_func = `mulMULTU;
                end
                div: begin
                    `grfAcc
                    ctrl_mul_func = `mulDIV;
                end
                divu: begin
                    `grfAcc
                    ctrl_mul_func = `mulDIVU;
                end
                // Trans Grf
                mfhi: begin
                    `accGrf
                    ctrl_alu_out_src = `fromHI;
                end
                mflo: begin
                    `accGrf
                    ctrl_alu_out_src = `fromLO;
                end
                mthi: begin
                    `grfAcc
                    ctrl_mul_func = `mulSetHI;
                end
                mtlo: begin
                    `grfAcc
                    ctrl_mul_func = `mulSetLO;
                end
                // Jump
                jalr: begin
                    `jumpAndSavePC
                    ctrl_jump = `jumpReg;
                    ctrl_grf_wa_src = `toGrfRd;
                end
                jr: begin
                    ctrl_jump = `jumpReg;
                end
                default: 
                    unknownInstr = 1;
            endcase
        end
        special2:
            case (funct)
                madd: begin
                    `grfAcc
                    ctrl_mul_func = `mulMADD;
                end
                maddu: begin
                    `grfAcc
                    ctrl_mul_func = `mulMADDU;
                end
                //mul:
                msub: begin
                    `grfAcc
                    ctrl_mul_func = `mulMSUB;
                end
                msubu: begin
                    `grfAcc
                    ctrl_mul_func = `mulMSUBU;
                end
                default: 
                    unknownInstr = 1;
            endcase
        // A & L Imm
        addi: begin
            `immALU
            ctrl_imm_src = `signExt;
            ctrl_alu_func = `aluAdd;
        end
        addiu: begin
            `immALU
            //ctrl_imm_src = `zeroExt; // this is wrong
            ctrl_imm_src = `signExt;
            ctrl_alu_func = `aluAdd;
            // do not check overflow
        end
        andi: begin
            `immALU
            ctrl_imm_src = `signExt;
            ctrl_alu_func = `aluAnd;
        end
        ori: begin
            `immALU
            ctrl_imm_src = `zeroExt;
            ctrl_alu_func = `aluOr;
        end
        xori: begin
            `immALU
            ctrl_imm_src = `zeroExt;
            ctrl_alu_func = `aluXor;
        end
        
        // Set Imm
        lui: begin
            `immALU
            ctrl_imm_src = `shiftLeft;
            ctrl_alu_out_src = `directImm;
        end
        slti: begin 
            `immALU
            ctrl_alu_func = `aluSLT;
        end
        sltiu: begin 
            `immALU
            //ctrl_imm_src = `zeroExt;
            ctrl_imm_src = `signExt;
            ctrl_alu_func = `aluSLTU;
        end
        // Load
        lb: begin
            `loadMemToRegRd
            ctrl_dm_extend = `signExt;
            ctrl_dm_width = `dmWidth1;
        end
        lbu: begin
            `loadMemToRegRd
            ctrl_dm_extend = `zeroExt;
            ctrl_dm_width = `dmWidth1;
        end
        lh: begin
            `loadMemToRegRd
            ctrl_dm_extend = `signExt;
            ctrl_dm_width = `dmWidth2;
        end
        lhu: begin
            `loadMemToRegRd
            ctrl_dm_extend = `zeroExt;
            ctrl_dm_width = `dmWidth2;
        end
        lw: begin
            `loadMemToRegRd
            ctrl_dm_width = `dmWidth4;
        end
        // lwl:
        // lwr:
        // Store
        sb: begin
            `storeRegRtTOMem
            ctrl_dm_width = `dmWidth1;
        end
        sh: begin
            `storeRegRtTOMem
            ctrl_dm_width = `dmWidth2;
        end
        sw: begin
            `storeRegRtTOMem
            ctrl_dm_width = `dmWidth4;
        end
        // swl:
        // swr:
        // Jump
        j: begin
            ctrl_jump = `jumpImm;
        end
        jal: begin
            `jumpAndSavePC
            ctrl_jump = `jumpImm;
            ctrl_grf_wa_src = `toGrf31;
        end

        // Branch
        beq: begin
            ctrl_cmp_func = `cmpEqual;
            ctrl_branch = 1;
        end
        bne: begin
            ctrl_cmp_func = `cmpNotEqual;
            ctrl_branch = 1;
        end
        blez: begin
            ctrl_cmp_func = `cmpNotGreaterThanZero;
            ctrl_branch = 1;
        end
        bgtz: begin
            ctrl_cmp_func = `cmpGreaterThanZero;
            ctrl_branch = 1;
        end
        // regimm
        regimm: begin
            case (rt)
                bltz: begin
                    ctrl_cmp_func = `cmpLessThanZero;
                    ctrl_branch = 1;
                end
                bgez: begin
                    ctrl_cmp_func = `cmpNotLessThanZero;
                    ctrl_branch = 1;
                end
                default:
                    unknownInstr = 1;
            endcase
        end
        // cop0
        // cop0: begin
        //     case (rs)
        //         mfcz:
        //         mtcz:
        //         copz: begin
        //             case (funct[4:0])
        //                 eret: 
        //                 default: 
        //             endcase
        //         end 
        //         default: 
        //     endcase
        // end
        default:
            unknownInstr = 1;
    endcase
end

always @(*) begin
    case (ctrl_grf_wa_src)
        `toGrfRt: grf_write_addr = instr[`rt];
        `toGrfRd: grf_write_addr = instr[`rd];
        `toGrf31: grf_write_addr = 5'd31;
    endcase
end

always @(*) begin
    if (unknownInstr) begin
        $display("Unkown Instruction: %h %h %h %h", op, rs, rt, funct);
        $finish();
    end
end
endmodule
