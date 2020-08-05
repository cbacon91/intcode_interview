class Intcode
  attr_reader :output

  def initialize(memory, input: [])
    @memory = memory.dup
    @pointer = 0
    @input = input.dup
    @output = []
  end

  def run
    loop do
      return @memory if @memory[@pointer] == 99

      meta = translate_instruction
      case meta[:opcode]
      when 1
        add_instruction meta
      when 2
        multiple_instruction meta
      when 3
        input_instruction meta
      when 4
        output_instruction meta
      else
        raise ArgumentError, 'unexpected opcode'
      end
    end
  end

  private

  def translate_instruction
    instruction_digits = @memory[@pointer].to_s.rjust(5, '0')

    {
      param_1_mode: instruction_digits[0].to_i,
      param_2_mode: instruction_digits[1].to_i,
      param_3_mode: instruction_digits[2].to_i,
      opcode: instruction_digits[3..4].to_i
    }
  end

  def add_instruction(meta)
    operate(meta) { |a, b| a + b }
  end

  def multiple_instruction(meta)
    operate(meta) { |a, b| a * b }
  end

  def operate(meta)
    a = get_param(meta[:param_1_mode])
    b = get_param(meta[:param_2_mode])

    set_param(meta[:param_3_mode], yield(a, b))
    advance_pointer
  end

  def get_param(mode)
    advance_pointer
    case mode
    when 0
      index = @memory[@pointer]
      @memory[index]
    # when 1
    #   @memory[@pointer]
    else
      raise ArgumentError, 'unknown parameter mode'
    end
  end

  def set_param(mode, new_value)
    advance_pointer
    case mode
    when 0
      index = @memory[@pointer]
      @memory[index] = new_value
    # when 1
    #   @memory[@pointer] = new_value
    else
      raise ArgumentError, 'unknown parameter mode'
    end
  end

  def input_instruction(meta)
    next_input = @input.shift
    set_param(meta[:param_1_mode], next_input)
    advance_pointer
  end

  def output_instruction(meta)
    output_value = get_param(meta[:param_1_mode])
    @output.push(output_value)
    advance_pointer
  end

  def advance_pointer
    @pointer += 1
  end
end
