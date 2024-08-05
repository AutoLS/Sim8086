#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";
#import "Math";

#load "decode.jai";
#load "sim.jai";

main :: ()
{
    args := get_command_line_arguments();
    path := args[1];
    data, success := read_entire_file(path);

    if !success
    {
        print("Error reading file, path does not exists.\n");
        return;
    }

    builder: String_Builder;
    init_string_builder(*builder);
    print_to_builder(*builder, "bits 16 %\n", path);
    
    ptr: *u8 = data.data;
    end := ptr + data.count;

    last_instruction_type := Transfer_Type.NONE;

    simulator: Sim8086;

    while ptr < end
    {
        new_instruction := decode_instruction(ptr);
        if last_instruction_type != new_instruction.transfer_type
        {
            print_to_builder(*builder, "\n%\n", new_instruction.transfer_type);
            last_instruction_type = new_instruction.transfer_type;
        }
        if new_instruction.type != .UNKNOWN
        {
            print_instruction(new_instruction, *builder);
            execute_instruction(*simulator, *new_instruction);
        }
        ptr += new_instruction.size;
/*
{
        advance_count: u8 = 0;
        instruction_string: string;
        b1 := <<ptr;
        ptr += 1;
        instruction_type := get_instruction_type(b1, << ptr);
        transfer_type := get_transfer_type(b1);

        if instruction_type == 
        {
            case .MOV;
            {
                //TODO: This can be refactored?
                if transfer_type == 
                {
                    case .RM_TO_FROM_REG;
                    {
                        advance_count, instruction_string = parse_rm_to_from_reg(ptr, b1);
                        print_to_builder(*builder, "mov %\n", instruction_string);
                    }
                    case .IM_TO_RM;
                    {
                        advance_count, instruction_string = parse_im_to_rm(ptr, b1, instruction_type);
                        print_to_builder(*builder, "mov %\n", instruction_string);
                    }
                    case .IM_TO_REG;
                    {
                        advance_count, instruction_string = parse_im_to_reg(ptr, b1);
                        print_to_builder(*builder, "mov %\n", instruction_string);
                    }
                    case .MEM_TO_ACCUM;
                    {
                        advance_count, instruction_string = parse_memory_to_accum(ptr, b1);
                        print_to_builder(*builder, "mov %\n", instruction_string);
                    }
                    case .ACCUM_TO_MEM;
                    {
                        advance_count, instruction_string = parse_memory_to_accum(ptr, b1, flip = true);
                        print_to_builder(*builder, "mov %\n", instruction_string);
                    }
                }
            }
            case .ADD;
            {
                transfer_type := b1 & OP_MASK;
                if transfer_type >> 2 == 
                {
                    case 0b00000000;
                    {
                        advance_count, instruction_string = parse_rm_to_from_reg(ptr, b1);
                        print_to_builder(*builder, "add %\n", instruction_string);
                    }
                    case 0b00100000;
                    {
                        advance_count, instruction_string = parse_im_to_rm(ptr, b1, instruction_type);
                        print_to_builder(*builder, "add %\n", instruction_string);
                    }
                    case 0b00000001;
                    {
                        advance_count, instruction_string = parse_memory_to_accum(ptr, b1, .ADD);
                        print_to_builder(*builder, "add %\n", instruction_string);
                    }
                }
            }
            case .SUB;
            {
                transfer_type := b1 & OP_MASK;
                if transfer_type >> 2 == 
                {
                    case 0b00001010;
                    {
                        advance_count, instruction_string = parse_rm_to_from_reg(ptr, b1);
                        print_to_builder(*builder, "sub %\n", instruction_string);
                    }
                    case 0b00100000;
                    {
                        advance_count, instruction_string = parse_im_to_rm(ptr, b1, .SUB);
                        print_to_builder(*builder, "sub %\n", instruction_string);
                    }
                    case 0b00001011;
                    {
                        advance_count, instruction_string = parse_memory_to_accum(ptr, b1, .SUB);
                        print_to_builder(*builder, "sub %\n", instruction_string);
                    }
                }
            }
            case .CMP;
            {
                transfer_type := b1 & OP_MASK;
                if transfer_type >> 2 == 
                {
                    case 0b00001110;
                    {
                        advance_count, instruction_string = parse_rm_to_from_reg(ptr, b1);
                        print_to_builder(*builder, "cmp %\n", instruction_string);
                    }
                    case 0b00100000;
                    {
                        advance_count, instruction_string = parse_im_to_rm(ptr, b1, .CMP);
                        print_to_builder(*builder, "cmp %\n", instruction_string);
                    }
                    case 0b00001111;
                    {
                        advance_count, instruction_string = parse_memory_to_accum(ptr, b1, .CMP);
                        print_to_builder(*builder, "cmp %\n", instruction_string);
                    }
                }
            }
            case .JE_JZ;    #through;
            case .JL_JNGE;  #through;
            case .JLE_JNG;  #through;
            case .JB_JNAE;  #through;
            case .JBE_JNA;  #through;
            case .JP_JPE;   #through;
            case .JO;       #through;
            case .JS;       #through;
            case .JNE_JNZ;  #through;
            case .JNL_JGE;  #through;
            case .JNLE_JG;  #through;
            case .JNB_JAE;  #through;
            case .JNBE_JA;  #through;
            case .JNP_JPO;  #through;
            case .JNO;
            {
                //print_to_builder(*builder, "% %\n", tprint("%", instruction_type), <<ptr);
                advance_count += 1;
            }      
        }
        
        ptr += advance_count;
}
*/
    }

    output := builder_to_string(*builder);

    make_directory_if_it_does_not_exist("output");

    output_path := tprint("output/%", trim_left(path, "hw/"));
    write_entire_file(output_path, output);
    
    print("Decoding complete. Output: %\n", output_path);

    new_context := context;
    push_context new_context {
        format_int := *context.print_style.default_format_int;
        format_int.base = 16;
        format_int.minimum_digits = size_of(s32);
        for simulator.registers
        {
            print("%: 0x%\n", cast(Register)it_index, it);
        }
    }

    test := 0b1111;
    print("test: %\n", test);
}