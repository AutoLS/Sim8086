#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";
#import "Math";
#import "Sim8086Lib";
#import "Hash_Table";

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

    table: instruction_table; 
    Sim86_Get8086InstructionTable(*table);

    simulator: Sim8086;
    array_reserve(*simulator.memory, 1024*1024);
    //init_sim8086(*simulator);

    while simulator.ip < data.count
    {
        decoded: instruction;
        Sim86_Decode8086Instruction(xx (data.count - simulator.ip), ptr + simulator.ip, *decoded);
        if decoded.Op 
        {
            print_decoded(decoded, *builder);
            execute_instruction(*simulator, decoded);
        }
        else
        {
            log_error("Unrecognized instruction");
            exit(-1);
        }
    }


    output := builder_to_string(*builder);

    make_directory_if_it_does_not_exist("output");

    output_path := tprint("output/%", trim_left(path, "hw/"));
    write_entire_file(output_path, output);
    
    print("Decoding complete. Output: %\n", output_path);
    print_registers(simulator);
}