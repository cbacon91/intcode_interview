require_relative 'memory'
require_relative 'instruction'

class Intcode
  attr_reader :output

  def initialize(memory, input: [])
    @memory = Memory.new(memory)
    @input = input.dup
    @output = []
  end

  def run
    loop do
      return @memory.raw if @memory[@memory.pointer] == 99

      opcode, param_1_mode, param_2_mode, param_3_mode = translate_instruction
      case opcode
      when 1
        AddInstruction
            .new(@memory, param_1_mode, param_2_mode, param_3_mode)
            .execute
      when 2
        MultiplyInstruction
            .new(@memory, param_1_mode, param_2_mode, param_3_mode)
            .execute
      when 3
        InputInstruction
            .new(@memory, @input, param_1_mode)
            .execute
      when 4
        OutputInstruction
            .new(@memory, @output, param_1_mode)
            .execute
      when 5
        JumpIfTrueInstruction
            .new(@memory, param_1_mode, param_2_mode)
            .execute
      when 6
        JumpIfFalseInstruction
            .new(@memory, param_1_mode, param_2_mode)
            .execute
      when 7
        LessThanInstruction
            .new(@memory, param_1_mode, param_2_mode, param_3_mode)
            .execute
      when 8
        EqualsInstruction
            .new(@memory, param_1_mode, param_2_mode, param_3_mode)
            .execute
      when 9
        adjust_relative_base_instruction param_1_mode
      else
        raise ArgumentError, "unexpected opcode #{opcode}"
      end

      @memory.advance_pointer unless JUMP_OPCODES.include? opcode
    end
  end

  JUMP_OPCODES = [5, 6].freeze

  private

  def translate_instruction
    instruction_digits = read_pointer.to_s.rjust(5, '0')

    opcode = instruction_digits[3..4].to_i
    param_1_mode = instruction_digits[2].to_i
    param_2_mode = instruction_digits[1].to_i
    param_3_mode = instruction_digits[0].to_i

    [opcode, param_1_mode, param_2_mode, param_3_mode]
  end

  def get_param(mode)
    @memory.advance_pointer

    case mode
    when 0
      param = @memory[read_pointer]
    when 1
      param = read_pointer
    when 2
      param = @memory[@memory.relative_base + read_pointer]
    else
      raise ArgumentError, 'unknown parameter mode'
    end

    param
  end

  def set_memory_for_param(mode, new_value)
    @memory.advance_pointer
    case mode
    when 0
      index = read_pointer
      @memory[index] = new_value
    when 1
      @memory[@memory.pointer] = new_value
    when 2
      @memory[@memory.relative_base + read_pointer] = new_value
    else
      raise ArgumentError, 'unknown parameter mode'
    end
  end

  def adjust_relative_base_instruction(param_mode)
    adjust_by = get_param(param_mode)
    @memory.relative_base += adjust_by
  end

  def read_pointer
    @memory[@memory.pointer]
  end
end
