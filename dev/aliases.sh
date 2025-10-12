# Dev - objdump
alias obj-asm='objdump -S --disassemble $1 > $1_obj_asm.s'
alias src-asm='gcc -S $1 -o _src_asm.s'

# Code with code-insiders
alias code-here="code-insiders . &; sleep 0.5; disown; exit;"
