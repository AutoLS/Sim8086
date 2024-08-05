Register :: enum u32
{
    AX;
    BX;
    CX;
    DX;
    SP;
    BP;
    SI;
    DI;
}

Sim_Flags :: enum u32
{
    Z_FLAG;
    S_FLAG;
}

Sim_Flag_Masks :: enum u32
{
    Z_FLAG :: 0b1;
    S_FLAG :: 0b10;
}

register_lookup :: (opcode: u16) -> s32
{
    if opcode == 
    {
        case 0b00000000; return xx Register.AX;
        case 0b00000001; return xx Register.CX;
        case 0b00000010; return xx Register.DX;
        case 0b00000011; return xx Register.BX;
        case 0b00000100; return xx Register.SP;
        case 0b00000101; return xx Register.BP;
        case 0b00000110; return xx Register.SI;
        case 0b00000111; return xx Register.DI;
        case; return -1;
    }
}

Sim8086 :: struct
{
    registers: [#run enum_highest_value(Register)+1] s32;
    flags: u8;
}

set_sim_flag :: (simulator: *Sim8086, flag_to_set: Sim_Flags)
{
    simulator.flags = simulator.flags | (cast(u8)1 << cast(u8)flag_to_set); 
}

toggle_sim_flag :: (simulator: *Sim8086, flag_to_set: Sim_Flags)
{
    simulator.flags = simulator.flags ^ (cast(u8)1 << cast(u8)flag_to_set); 
}

is_sim_flag_set :: (simulator: *Sim8086, flag_to_check: Sim_Flag_Masks)
{
    simulator.flags = simulator.flags & (xx flag_to_check);
}

execute_mov :: (simulator: *Sim8086, instruction: *Instruction)
{
    if instruction.transfer_type == 
    {
        case .RM_TO_FROM_REG;
        {
            dest_index := register_lookup(instruction.dest);
            src_index := register_lookup(instruction.src);
            simulator.registers[dest_index] = simulator.registers[src_index];
        }
        case .IM_TO_REG;
        {
            dest_index := register_lookup(instruction.dest);
            simulator.registers[dest_index] = instruction.s_data;
        }
    }
}

execute_add_sub_cmp :: (simulator: *Sim8086, instruction: *Instruction)
{
    
}

execute_instruction :: (simulator: *Sim8086, instruction: *Instruction)
{
    if instruction.type == 
    {
        case .MOV;
        {
            execute_mov(simulator, instruction);
        }
    }
}