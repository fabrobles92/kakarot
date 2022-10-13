// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc, get_ap
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.invoke import invoke
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import Uint256

// Project dependencies
from openzeppelin.security.safemath.library import SafeUint256

// Internal dependencies
from kakarot.model import model
from utils.utils import Helpers
from kakarot.execution_context import ExecutionContext
from kakarot.stack import Stack
from kakarot.instructions.push_operations import PushOperations
from kakarot.instructions.arithmetic_operations import ArithmeticOperations

namespace EVMInstructions {
    // Decodes the current opcode and execute associated function
    // @param instructions the instruction set
    // @param opcode the opcode value
    // @param ctx the execution context
    func decode_and_execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        instructions: felt*, ctx: model.ExecutionContext*
    ) -> model.ExecutionContext* {
        alloc_locals;
        let pc = ctx.program_counter;

        // Revert if pc < 0
        with_attr error_message("Kakarot: InvalidCodeOffset") {
            assert_nn(pc);
        }

        local opcode;

        %{
            # Check if pc > len(code) and process it as a STOP if true
            if ids.pc > ids.ctx.code_len:
                ids.opcode = 0
            else:
                ids.opcode = memory[ids.ctx.code + ids.pc]
        %}

        local opcode_exist;

        // Check if opcode exists
        %{
            if memory.get(ids.instructions + ids.opcode) == None:
                ids.opcode_exist = 0
            else:
                ids.opcode_exist = 1
        %}

        // Revert if opcode does not exist
        with_attr error_message("Kakarot: UnknownOpcode") {
            assert opcode_exist = TRUE;
        }

        // move program counter + 1 after opcode is read
        let ctx = ExecutionContext.increment_program_counter(ctx, 1);

        // Read opcode in instruction set
        let function_codeoffset_felt = instructions[opcode];
        let function_codeoffset = cast(function_codeoffset_felt, codeoffset);
        let (function_ptr) = get_label_location(function_codeoffset);

        // Prepare implicit arguments
        let implicit_args_len = decode_and_execute.ImplicitArgs.SIZE;
        tempvar implicit_args = new decode_and_execute.ImplicitArgs(syscall_ptr, pedersen_ptr, range_check_ptr);

        // Build arguments array
        let (args_len: felt, args: felt*) = prepare_arguments(
            ctx, implicit_args_len, implicit_args
        );

        // Invoke opcode function
        invoke(function_ptr, args_len, args);

        // Retrieve results
        let (ap_val) = get_ap();
        let implicit_args: decode_and_execute.ImplicitArgs* = cast(ap_val - implicit_args_len - 1, decode_and_execute.ImplicitArgs*);
        // Update implicit arguments
        let syscall_ptr = implicit_args.syscall_ptr;
        let pedersen_ptr = implicit_args.pedersen_ptr;
        let range_check_ptr = implicit_args.range_check_ptr;

        // Get actual return value from ap
        return cast([ap_val - 1], model.ExecutionContext*);
    }

    // Adds an instruction in the passed instructions set
    // @param instructions the instruction set
    // @param opcode the opcode value
    // @param function the function to execute for the specified opcode
    func add_instruction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        instructions: felt*, opcode: felt, function: codeoffset
    ) {
        assert [instructions + opcode] = cast(function, felt);
        return ();
    }

    // 0x00 - STOP
    // Halts execution
    // Since: Frontier
    // Group: Stop and Arithmetic Operations
    func exec_stop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ctx_ptr: model.ExecutionContext*
    ) -> (ctx: model.ExecutionContext*) {
        %{ print("0x00 - STOP") %}
        let ctx_ptr = ExecutionContext.stop(ctx_ptr);
        return (ctx=ctx_ptr);
    }

    func prepare_arguments(ctx: felt*, implicit_args_len: felt, implicit_args: felt*) -> (
        args_len: felt, args: felt*
    ) {
        alloc_locals;

        let (args: felt*) = alloc();
        memcpy(args, implicit_args, implicit_args_len);
        let ctx_value = cast(ctx, felt);
        assert args[implicit_args_len] = ctx_value;

        return (implicit_args_len + 1, args);
    }

    // Generates the instructions set for the EVM
    func generate_instructions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> felt* {
        alloc_locals;
        // init instructions
        let (instructions: felt*) = alloc();

        // add instructions

        // add 0s: Stop and Arithmetic Operations
        // 0x00 - STOP
        add_instruction(instructions, 0, exec_stop);
        // 0x01 - ADD
        add_instruction(instructions, 1, ArithmeticOperations.exec_add);

        // add 6s: Push operations
        // 0x60 - PUSH1
        add_instruction(instructions, 96, PushOperations.exec_push1);
        // 0x61 - PUSH2
        add_instruction(instructions, 97, PushOperations.exec_push2);
        // 0x62 - PUSH3
        add_instruction(instructions, 98, PushOperations.exec_push3);
        // 0x63 - PUSH4
        add_instruction(instructions, 99, PushOperations.exec_push4);
        // 0x64 - PUSH5
        add_instruction(instructions, 100, PushOperations.exec_push5);
        // 0x65 - PUSH6
        add_instruction(instructions, 101, PushOperations.exec_push6);
        // 0x66 - PUSH7
        add_instruction(instructions, 102, PushOperations.exec_push7);
        // 0x67 - PUSH8
        add_instruction(instructions, 103, PushOperations.exec_push8);
        // 0x68 - PUSH9
        add_instruction(instructions, 104, PushOperations.exec_push9);
        // 0x69 - PUSH10
        add_instruction(instructions, 105, PushOperations.exec_push10);
        // 0x6a - PUSH11
        add_instruction(instructions, 106, PushOperations.exec_push11);
        // 0x6b - PUSH12
        add_instruction(instructions, 107, PushOperations.exec_push12);
        // 0x6c - PUSH13
        add_instruction(instructions, 108, PushOperations.exec_push13);
        // 0x6d - PUSH14
        add_instruction(instructions, 109, PushOperations.exec_push14);
        // 0x6e - PUSH15
        add_instruction(instructions, 110, PushOperations.exec_push15);
        // 0x6f - PUSH16
        add_instruction(instructions, 111, PushOperations.exec_push16);
        // 0x70 - PUSH17
        add_instruction(instructions, 112, PushOperations.exec_push17);
        // 0x71 - PUSH18
        add_instruction(instructions, 113, PushOperations.exec_push18);
        // 0x72 - PUSH19
        add_instruction(instructions, 114, PushOperations.exec_push19);
        // 0x73 - PUSH20
        add_instruction(instructions, 115, PushOperations.exec_push20);
        // 0x74 - PUSH21
        add_instruction(instructions, 116, PushOperations.exec_push21);
        // 0x75 - PUSH22
        add_instruction(instructions, 117, PushOperations.exec_push22);
        // 0x76 - PUSH23
        add_instruction(instructions, 118, PushOperations.exec_push23);
        // 0x77 - PUSH24
        add_instruction(instructions, 119, PushOperations.exec_push24);
        // 0x78 - PUSH25
        add_instruction(instructions, 120, PushOperations.exec_push25);
        // 0x79 - PUSH26
        add_instruction(instructions, 121, PushOperations.exec_push26);
        // 0x7a - PUSH27
        add_instruction(instructions, 122, PushOperations.exec_push27);
        // 0x7b - PUSH28
        add_instruction(instructions, 123, PushOperations.exec_push28);
        // 0x7c - PUSH29
        add_instruction(instructions, 124, PushOperations.exec_push29);
        // 0x7d - PUSH30
        add_instruction(instructions, 125, PushOperations.exec_push30);
        // 0x7e - PUSH31
        add_instruction(instructions, 126, PushOperations.exec_push31);
        // 0x7f - PUSH32
        add_instruction(instructions, 127, PushOperations.exec_push32);

        return instructions;
    }
}