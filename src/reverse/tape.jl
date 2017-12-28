###############
# Instruction #
###############

struct Instruction{F,I<:Tuple,O}
    func::F
    input::I
    output::O
end

Instruction(f, input, output) = Instruction(f, tuplize(input), output)

function reversepass!(instr::Instruction)
    back!(instr.func, instr.input..., instr.output)
    return nothing
end

########
# Tape #
########

struct Tape
    instructions::Vector{Instruction}
end

Tape() = Tape(Vector{Instruction}())

Base.push!(t::Tape, i::Instruction) = push!(t.instructions, i)

Base.empty!(t::Tape) = (empty!(t.instructions); t)

function reversepass!(tape::Tape)
    for instr in Iterators.reverse(tape.instructions)
        reversepass!(instr)::Void
    end
    return nothing
end
