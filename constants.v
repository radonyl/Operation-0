// Instruction Defination
`define op 31:26
`define rs 25:21
`define rt 20:16
`define rd 15:11
`define shamt 10:6
`define funct 5:0
`define i16 15:0
`define i26 25:0
// ALU Function Code
`define aluDisable 0
`define aluAdd 1
`define aluSub 2
`define aluAnd 3
`define aluOr 4
`define aluXor 5
`define aluNor 6
`define aluSL 7
`define aluSR 8
`define aluSRA 9
`define aluSLT 10
`define aluSLTU 11
// MUL Function Code
`define mulMULT 0
`define mulMULTU 1
`define mulMADD 2
`define mulMADDU 3
`define mulMSUB 4
`define mulMSUBU 5
`define mulDIV 6
`define mulDIVU 7
`define mulSetLO 8
`define mulSetHI 9
`define mulDisable 15

// CMP Function Code
`define cmpGreaterThanZero 0
`define cmpNotLessThanZero 1
`define cmpLessThanZero 3
`define cmpNotGreaterThanZero 4
`define cmpEqual 5
`define cmpNotEqual 6

// DM withd 
`define dmWidth1 0
`define dmWidth2 1
`define dmWidth4 2

// ctrl jump
`define jumpDisable 0
`define jumpImm 1
`define jumpReg 2

// MUX defination
// stage if pc src
`define fromPCInc4_F 0
`define fromNPC_D 1
// stage ex alu src
`define fromGrfRt 0
`define fromGrfRs 1 // for src a
`define fromImm 2
`define fromShamt 3 // for src b

// stage wb grf wd src
`define fromALU 0
`define fromDm 1
`define fromPC 2

// stage ex grf wa src
`define toGrfRt 0
`define toGrfRd 1
`define toGrf31 2

// stage ex imm src
`define signExt 0
`define zeroExt 1
`define shiftLeft 2


// stage ex alu out src
`define fromALUOut 0
`define fromLO 1
`define fromHI 2
`define directImm 3

// Forward
`define doNotForward 0
`define fwdFrom_AO_M 1 // book 10
`define fwdFrom_WD3_W 2 // book 01
