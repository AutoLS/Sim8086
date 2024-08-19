Registers_Name :: enum u32 
{
    none;
    ax;
    bx;
    cx;
    dx;
    sp;
    bp;
    si;
    di;
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

Register_Data :: struct 
{
    union
    {
        data: u16;
        bytes: Bytes;
        Bytes :: struct
        {
            low: u8;
            high: u8;
        }
    }
}

Sim8086 :: struct
{
    registers: Table(u32, Register_Data);
    memory: [..] u8;
    ip: u32;
    flags: u8;
}

init_sim8086 :: (sim: *Sim8086)
{
    for 0 .. enum_highest_value(Registers_Name)
    {
        table_set(*sim.registers, xx it, .{});
    }
}

set_sim_flag :: (simulator: *Sim8086, flag_to_set: Sim_Flags)
{
    simulator.flags = simulator.flags | (cast(u8)1 << cast(u8)flag_to_set); 
}

clear_sim_flag :: (simulator: *Sim8086, flag_to_clear: Sim_Flags)
{
    simulator.flags =  simulator.flags & ~(cast(u8)1 << cast(u8)flag_to_clear);
}

toggle_sim_flag :: (simulator: *Sim8086, flag_to_set: Sim_Flags)
{
    simulator.flags = simulator.flags ^ (cast(u8)1 << cast(u8)flag_to_set); 
}

is_sim_flag_set :: (simulator: *Sim8086, flag_to_check: Sim_Flags) -> u8
{
    return (simulator.flags >> cast(u8)flag_to_check) & cast(u8)1;
}

set_register_data :: (simulator: *Sim8086, register: register_access, value: u16)
{
    new_data: Register_Data;
    new_data.data = value;
    table_set(*simulator.registers, register.Index, new_data);
}

get_register_data :: (simulator: *Sim8086, register: register_access) -> Register_Data
{
    result, success := table_find(*simulator.registers, register.Index);
    if success return result; else return .{};
}

execute_mov :: (simulator: *Sim8086, i: instruction)
{
    dest := i.Operands[0]; 
    src := i.Operands[1];

    if src.Type == 
    {
        case .Register;
        {
            src_data := get_register_data(simulator, src.Register);
            set_register_data(simulator, dest.Register, src_data.data);
        }
        case .Immediate;
        {
            src_data := src.Immediate.Value;
            set_register_data(simulator, dest.Register, xx src_data);
        }
        case .Memory;
        {
            
        }
    }
    simulator.ip += i.Size;
}

execute_add :: (simulator: *Sim8086, i: instruction)
{
    dest := i.Operands[0]; 
    src := i.Operands[1];
    dest_data := get_register_data(simulator, dest.Register);
    result: u16;
    signed: s16;
    if src.Type ==
    {
        case .Register;
        {
            src_data := get_register_data(simulator, src.Register);
            result = dest_data.data + src_data.data;
            set_register_data(simulator, dest.Register, result);
        }
        case .Immediate;
        {
            src_data := src.Immediate.Value;
            result = dest_data.data + xx src_data;
            set_register_data(simulator, dest.Register, result);
        }
    }

    signed = <<(cast(*s16)*result);

    clear_sim_flag(simulator, .Z_FLAG);
    clear_sim_flag(simulator, .S_FLAG);

    if signed < 0 then set_sim_flag(simulator, .S_FLAG);
    if result == 0 then set_sim_flag(simulator, .Z_FLAG);

    simulator.ip += i.Size;
}

execute_sub :: (simulator: *Sim8086, i: instruction)
{
    dest := i.Operands[0]; 
    src := i.Operands[1];
    result: u16;
    signed: s16;
    dest_data := get_register_data(simulator, dest.Register);
    if src.Type ==
    {
        case .Register;
        {
            src_data := get_register_data(simulator, src.Register);
            result = dest_data.data - src_data.data;
            set_register_data(simulator, dest.Register, result);
        }
        case .Immediate;
        {
            src_data := src.Immediate.Value;
            result = dest_data.data - cast(u16)src_data;
            set_register_data(simulator, dest.Register, result);
        }
    }

    signed = <<(cast(*s16)*result);

    clear_sim_flag(simulator, .Z_FLAG);
    clear_sim_flag(simulator, .S_FLAG);

    if signed < 0 then set_sim_flag(simulator, .S_FLAG);
    if result == 0 then set_sim_flag(simulator, .Z_FLAG);

    simulator.ip += i.Size;
}

execute_cmp :: (simulator: *Sim8086, i: instruction)
{
    dest := i.Operands[0]; 
    src := i.Operands[1];
    result: u16;
    signed: s16;
    dest_data := get_register_data(simulator, dest.Register);
    if src.Type ==
    {
        case .Register;
        {
            src_data := get_register_data(simulator, src.Register);
            result = dest_data.data - src_data.data;
        }
        case .Immediate;
        {
            src_data := src.Immediate.Value;
            result = dest_data.data - cast(u16)src_data;
        }
    }

    signed = <<(cast(*s16)*result);

    clear_sim_flag(simulator, .Z_FLAG);
    clear_sim_flag(simulator, .S_FLAG);

    if signed < 0 then set_sim_flag(simulator, .S_FLAG);
    if result == 0 then set_sim_flag(simulator, .Z_FLAG);

    simulator.ip += i.Size;
}

jump :: (simulator: *Sim8086, i: instruction)
{
    simulator.ip += i.Size;
    //print("type: %, ip: %, value: %\n", i.Operands[0].Type, simulator.ip, i.Operands[0].Immediate.Value);
    z_flag := cast(bool)is_sim_flag_set(simulator, .Z_FLAG);
    //print("z_flag: %\n", z_flag);
    if !z_flag
    {
        simulator.ip = cast(u32)(cast(s32)simulator.ip + i.Operands[0].Immediate.Value);
    }
    
}

execute_instruction :: (simulator: *Sim8086, i: instruction)
{
    if i.Op == 
    {
        case .mov; execute_mov(simulator, i);
        case .add; execute_add(simulator, i);
        case .sub; execute_sub(simulator, i);
        case .cmp; execute_cmp(simulator, i);
        case .jne; jump(simulator, i);
    }
}

print_registers :: (simulator: Sim8086)
{
    for 0 .. enum_highest_value(Registers_Name)
    {
        register, found := table_find(*simulator.registers, xx it);
        if found
        {
            signed: s16 = <<(cast(*s16)*register.data); //wtf this works :om:
            print("Register: % (Value: % (%), low: %, high: %)\n", cast(Registers_Name)it, register.data, signed, register.bytes.low, register.bytes.high);
        }
    }

    print("%: %\n", Sim_Flags.Z_FLAG, is_sim_flag_set(*simulator, .Z_FLAG));
    print("%: %\n", Sim_Flags.S_FLAG, is_sim_flag_set(*simulator, .S_FLAG));
}
