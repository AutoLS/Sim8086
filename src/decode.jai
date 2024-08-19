OP_MASK :: 0b11111111;
D_MASK :: 0b00000010;
W_MASK :: 0b00000001;
SW_MASK :: 0b00000011;
MOD_MASK:: 0b11000000;
REG_MASK:: 0b00111000;
RM_MASK:: 0b00000111;

BYTE_STRING :: "byte";
WORD_STRING :: "word";

Instruction_Type :: enum u32
{
    UNKNOWN;
    MOV;
    ADD;
    SUB;
    CMP;
    JE_JZ;
    JL_JNGE;
    JLE_JNG;
    JB_JNAE;
    JBE_JNA;
    JP_JPE;
    JO;
    JS;
    JNE_JNZ;
    JNL_JGE;
    JNLE_JG;
    JNB_JAE;
    JNBE_JA;
    JNP_JPO;
    JNO;
}

Transfer_Type :: enum u32
{
    NONE;
    RM_TO_FROM_REG;
    IM_TO_RM;
    IM_TO_REG;
    MEM_TO_ACCUM;
    ACCUM_TO_MEM;
    IM_TO_ACCUM;
}

Mode_Type :: enum u32
{
    NONE;
    MEMORY_NO_DISPLACEMENT;
    MEMORY_8BIT_DISPLACEMENT;
    MEMORY_16BIT_DISPLACEMENT;
    REGISTER_NO_DISPLACEMENT;
}

Instruction :: struct
{
    type: Instruction_Type;
    transfer_type: Transfer_Type;
    mode: Mode_Type;

    op_byte: u8;
    displacement: u16;
    data: u16;
    s_data: s16;

    operand_l: string;
    operand_r: string;

    dest: u16;
    src: u16;

    sign: bool;
    wide: bool;

    size: u32;

#place displacement;
    dis_8bit: u8;
#place data;
    data_8bit: u8;
}

is_reg_to_reg :: (op: u8) -> bool
{
    return op & MOD_MASK == 0b11000000;
}

is_reg_dest :: (op: u8) -> bool
{
    return op & D_MASK == 0b00000010;
}

is_wide :: (op: u8) -> bool
{
    return op & W_MASK == 0b00000001;
}

get_instruction_type :: (b: u8, b2: u8) -> Instruction_Type
{
    instruction: Instruction_Type;
    code := b & OP_MASK;

    if b & REG_MASK ==
    {
        case 0b00000000; 
        {
            if b2 & REG_MASK == 
            {
                case 0b00000000; instruction = .ADD;
                case 0b00101000; instruction = .SUB;
                case 0b00111000; instruction = .CMP;
            }
                
        }
        case 0b00101000; instruction = .SUB;
        case 0b00111000; instruction = .CMP;
    }

    if code >> 2 == 0b00100010 || code >> 4 == 0b00001011
    {
        instruction = .MOV;
    }
    else if code >> 1 == 
    {
        case 0b01100011; #through;
        case 0b01010000; #through;
        case 0b01010001; instruction = .MOV;
    }

    if code == 
    {
        case 0b01110100; instruction = .JE_JZ;
        case 0b01111100; instruction = .JL_JNGE;
        case 0b01111110; instruction = .JLE_JNG;
        case 0b01110010; instruction = .JB_JNAE;
        case 0b01110110; instruction = .JBE_JNA;
        case 0b01111010; instruction = .JP_JPE;
        case 0b01110000; instruction = .JO;
        case 0b01111000; instruction = .JS;
        case 0b01110101; instruction = .JNE_JNZ;
        case 0b01111101; instruction = .JNL_JGE;
        case 0b01111111; instruction = .JNLE_JG;
        case 0b01110011; instruction = .JNB_JAE;
        case 0b01110111; instruction = .JNBE_JA;
        case 0b01111011; instruction = .JNP_JPO;
        case 0b01110001; instruction = .JNO;
    }
    

    return instruction;
}

get_data_transfer_type :: (instruction: Instruction_Type, b: u8) -> Transfer_Type
{
    transfer_type: Transfer_Type;
    if instruction == 
    {
        case .MOV;
        {
            opcode := b & OP_MASK;
            if opcode >> 2 == 0b00100010 then transfer_type = .RM_TO_FROM_REG;
            if opcode >> 1 == 
            {
                case 0b01100011; transfer_type = .IM_TO_RM;
                case 0b01010000; transfer_type = .MEM_TO_ACCUM;
                case 0b01010001; transfer_type = .ACCUM_TO_MEM;
            }

            if opcode >> 4 == 0b00001011 then transfer_type = .IM_TO_REG;
        }
        case .ADD;
        {
            opcode := b & OP_MASK;
            if opcode >> 2 ==
            {
                case 0b0; transfer_type = .RM_TO_FROM_REG;
                case 0b00100000; transfer_type = .IM_TO_RM;
                case 0b00000001; transfer_type = .IM_TO_ACCUM;
            }
        }
        case .SUB;
        {
            opcode := b & OP_MASK;
            if opcode >> 2 ==
            {
                case 0b00001010; transfer_type = .RM_TO_FROM_REG;
                case 0b00100000; transfer_type = .IM_TO_RM;
                case 0b00001011; transfer_type = .IM_TO_ACCUM;
            }
        }
        case .CMP;
        {
            opcode := b & OP_MASK;
            if opcode >> 2 ==
            {
                case 0b00001110; transfer_type = .RM_TO_FROM_REG;
                case 0b00100000; transfer_type = .IM_TO_RM;
                case 0b00001111; transfer_type = .IM_TO_ACCUM;
            }
        }
        case; transfer_type = .NONE;
    }

    return transfer_type;
}

get_mode_type :: (b: u8) -> Mode_Type
{
    mode := b & MOD_MASK;
    if mode == 
    {
        case 0b11000000; return .REGISTER_NO_DISPLACEMENT;
        case 0b10000000; return .MEMORY_16BIT_DISPLACEMENT;
        case 0b01000000; return .MEMORY_8BIT_DISPLACEMENT;
        case 0b00000000; return .MEMORY_NO_DISPLACEMENT;
        case; return .NONE;
    }

    return 0;
}

get_reg_string :: (wide: bool, reg: u8) -> string
{
    if wide
    {
        if reg == 
        {
            case 0b00000000; return "ax";
            case 0b00000001; return "cx";
            case 0b00000010; return "dx";
            case 0b00000011; return "bx";
            case 0b00000100; return "sp";
            case 0b00000101; return "bp";
            case 0b00000110; return "si";
            case 0b00000111; return "di";
            case; return "";
        }
    }
    else
    {
        if reg == 
        {
            case 0b00000000; return "al";
            case 0b00000001; return "cl";
            case 0b00000010; return "dd";
            case 0b00000011; return "bl";
            case 0b00000100; return "ah";
            case 0b00000101; return "ch";
            case 0b00000110; return "dh";
            case 0b00000111; return "bh";
            case; return "";
        }
    }
}

get_mem_no_displacement_string :: (b: u8) -> string
{
    result: string;
    if b & RM_MASK ==
    {
        case 0b00000000; result = "[bx + si]";
        case 0b00000001; result = "[bx + di]";
        case 0b00000010; result = "[bp + si]";
        case 0b00000011; result = "[bp + di]";
        case 0b00000100; result = "[si]";
        case 0b00000101; result = "[di]";
        case 0b00000110; result = "[bp]";
        case 0b00000111; result = "[bx]";
    }

    return result;
}

get_mem_displacement_string :: (b: u8, displacement: s16) -> string
{
    result: string;
    sign: string = " +";
    if displacement < 0
    {
        displacement = xx abs(displacement);
        sign = " -";
    }

    displacement_string := tprint(" %", displacement);

    if displacement == 0
    {
        sign = "";
        displacement_string = "";
    }

    if b & RM_MASK ==
    {
        case 0b00000000; result = tprint("[bx + si%1%2]", sign, displacement_string);
        case 0b00000001; result = tprint("[bx + di%1%2]", sign, displacement_string);
        case 0b00000010; result = tprint("[bp + si%1%2]", sign, displacement_string);
        case 0b00000011; result = tprint("[bp + di%1%2]", sign, displacement_string);
        case 0b00000100; result = tprint("[si%1%2]", sign, displacement_string);
        case 0b00000101; result = tprint("[di%1%2]", sign, displacement_string);
        case 0b00000110; result = tprint("[bp%1%2]", sign, displacement_string);
        case 0b00000111; result = tprint("[bx%1%2]", sign, displacement_string);
    }

    return result;
}

set_data_8bit :: (instruction: *Instruction, ptr: *u8)
{
    instruction.data = << ptr;
    data: s8 = << cast(*s8)ptr;
    instruction.operand_r = tprint("%", data);
    instruction.s_data = xx data;
    instruction.sign = data < 0;
    instruction.size += 1;
}

set_data_16bit :: (instruction: *Instruction, ptr: *u8)
{
    instruction.data = << cast(*u16)ptr;
    data: s16 = << cast(*s16)ptr;
    instruction.operand_r = tprint("%", data);
    instruction.s_data = data;
    instruction.sign = data < 0;
    instruction.size += 2;
}

decode_data :: (instruction: *Instruction, ptr: *u8)
{
    if instruction.type == .MOV
    {
        if instruction.wide
        {
            set_data_16bit(instruction, ptr);
        }
        else 
        {
            set_data_8bit(instruction, ptr);
        }
    }
    else
    {
        if instruction.op_byte & SW_MASK == W_MASK
        {
            set_data_16bit(instruction, ptr);
        }
        else
        {
            set_data_8bit(instruction, ptr);
        }
    }
}

decode_rm_to_from_reg :: (instruction: *Instruction, data_ptr: *u8)
{
    b2 := << (data_ptr+1);
    instruction.size += 1;

    reg := b2 & REG_MASK;

    src_string: string;
    dest_string: string;

    if instruction.mode == 
    {
        case .MEMORY_NO_DISPLACEMENT;
        {
            src_string = get_mem_no_displacement_string(b2);
            if b2 & RM_MASK == 0b00000110
            {
                instruction.displacement = << cast(*u16)(data_ptr+2);
                instruction.size += 2;

                src_string = tprint("[%]", instruction.displacement);
                instruction.src = instruction.displacement;
            }

            dest_string = get_reg_string(instruction.wide, reg >> 3);
            instruction.dest = reg >> 3;
        }
        case .MEMORY_8BIT_DISPLACEMENT;
        {
            instruction.dis_8bit = << (data_ptr+2);
            displacement := << cast(*s8)(data_ptr+2);
            instruction.size += 1;

            instruction.sign = displacement < 0;
            
            src_string = get_mem_displacement_string(b2, xx displacement);
            dest_string = get_reg_string(instruction.wide, reg >> 3);
        }
        case .MEMORY_16BIT_DISPLACEMENT;
        {
            instruction.displacement = << cast(*u16)(data_ptr+2);
            displacement := << cast(*s16)(data_ptr+2);
            instruction.size += 2;

            instruction.sign = displacement < 0;
            
            src_string = get_mem_displacement_string(b2, displacement);
            dest_string = get_reg_string(instruction.wide, reg >> 3);
        }
        case .REGISTER_NO_DISPLACEMENT; 
        {
            instruction.src = b2 & RM_MASK;
            instruction.dest = reg >> 3;
            src_string = get_reg_string(instruction.wide, b2 & RM_MASK);
            dest_string = get_reg_string(instruction.wide, reg >> 3);
        }
    }

    if !is_reg_dest(instruction.op_byte) 
    {
        dest_string, src_string = src_string, dest_string;
        instruction.dest, instruction.src = instruction.src, instruction.dest;
    }

    instruction.operand_l = dest_string;
    instruction.operand_r = src_string;
}

decode_im_to_rm :: (instruction: *Instruction, data_ptr: *u8)
{
    b2 := << (data_ptr+1);
    instruction.size += 1;

    if instruction.mode == 
    {
        case .MEMORY_NO_DISPLACEMENT;
        {
            instruction.operand_l = get_mem_no_displacement_string(b2);

            decode_data(instruction, data_ptr+2);
            if b2 & RM_MASK == 0b00000110
            {
                instruction.displacement = << cast(*u16)(data_ptr+2);
                displacement: s16;
                displacement = << cast(*s16)(data_ptr+2);
                instruction.size += 2;

                instruction.operand_l = tprint("[%]", displacement);
                decode_data(instruction, data_ptr+4);
            }            
        }
        case .MEMORY_8BIT_DISPLACEMENT;
        {
            displacement: s8;
            displacement = xx <<(data_ptr+2);
            instruction.dis_8bit = << (data_ptr+2);
            instruction.size += 1;

            instruction.operand_l = get_mem_displacement_string(b2, xx displacement);
            decode_data(instruction, data_ptr+3);
        }
        case .MEMORY_16BIT_DISPLACEMENT;
        {
            displacement: s16;
            displacement = << cast(*s16)(data_ptr+2);
            instruction.displacement = << (data_ptr+2);
            instruction.size += 2;

            instruction.operand_l = get_mem_displacement_string(b2, xx displacement);
            decode_data(instruction, data_ptr+4);
        }
        case .REGISTER_NO_DISPLACEMENT; 
        {
            instruction.operand_l = get_reg_string(instruction.wide, b2 & RM_MASK);
            decode_data(instruction, data_ptr+2);
        }
    }
}

decode_im_to_reg :: (instruction: *Instruction, ptr: *u8)
{
    if instruction.type == 
    {
        case .MOV;
        {
            instruction.wide = is_wide(instruction.op_byte >> 3);
            decode_data(instruction, ptr+1);
            instruction.operand_l = get_reg_string(instruction.wide, instruction.op_byte & RM_MASK);
            instruction.dest = instruction.op_byte & RM_MASK;
            instruction.src = instruction.data;
        }
    }
}

decode_mem_to_from_accum :: (instruction: *Instruction, ptr: *u8)
{
    if instruction.wide 
    {
        set_data_16bit(instruction, ptr+1);
    }
    else
    {
        set_data_8bit(instruction, ptr+1);
    }
    
    if instruction.type == .MOV
    {
        instruction.operand_r = tprint("[%]", instruction.operand_r);
    }

    instruction.operand_l = "ax";

    if instruction.transfer_type == .ACCUM_TO_MEM
    {
        instruction.operand_l, instruction.operand_r = instruction.operand_r, instruction.operand_l;
    }
}

decode_instruction :: (ptr: *u8) -> Instruction
{
    b1 := << ptr;
    b2 := << (ptr+1);
    instruction: Instruction;
    instruction.op_byte = b1;
    instruction.size += 1;
    instruction.type = get_instruction_type(b1, b2);
    instruction.transfer_type = get_data_transfer_type(instruction.type, b1);
    instruction.mode = get_mode_type(b2);
    instruction.wide = is_wide(instruction.op_byte);

    if instruction.transfer_type == 
    {
        case .RM_TO_FROM_REG; decode_rm_to_from_reg(*instruction, ptr);
        case .IM_TO_RM; decode_im_to_rm(*instruction, ptr);
        case .IM_TO_REG; decode_im_to_reg(*instruction, ptr);
        case .MEM_TO_ACCUM; #through;
        case .ACCUM_TO_MEM; decode_mem_to_from_accum(*instruction, ptr);
        case .IM_TO_ACCUM; decode_mem_to_from_accum(*instruction, ptr);
    }

    return instruction;
}

print_instruction :: (instruction: Instruction, builder: *String_Builder)
{
    type_string := to_lower_copy_new(tprint("%", instruction.type));
    print_to_builder(builder, "% %, %\n", type_string, instruction.operand_l, instruction.operand_r);
}

print_decoded :: (decoded: instruction, builder: *String_Builder)
{
    //print("%\n", decoded.Op);
    operand_l := decoded.Operands[0];
    reg_l := to_string(Sim86_RegisterNameFromOperand(*operand_l.Register));
    operand_r := decoded.Operands[1];
    reg_r := to_string(Sim86_RegisterNameFromOperand(*operand_r.Register));

    print_to_builder(builder, "% ", decoded.Op);

    if operand_l.Type == 
    {
        case .Register; print_to_builder(builder, "%", reg_l);
        case .Immediate; print_to_builder(builder, "%", operand_l.Immediate.Value);
    }

    if operand_r.Type == 
    {
        case .Register; print_to_builder(builder, ", %", reg_r);
        case .Immediate; print_to_builder(builder, ", %", operand_r.Immediate.Value);
    }
    print_to_builder(builder, "\n");
}