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