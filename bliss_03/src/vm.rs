use crate::instruction::Opcode;

#[derive(Debug, PartialEq)]
struct Definition {
    opcode: u16,
	name: String,
	body: Vec<u8>,
}

pub struct VM {
    registers: [i32; 32],
    pc: usize,
    program: Vec<u8>,
    remainder: u32,
}

macro_rules! bin_op {
    ( $sel:ident, $x:tt ) => {
        let register1 = $sel.registers[$sel.next_8_bits() as usize];
        let register2 = $sel.registers[$sel.next_8_bits() as usize];
        $sel.registers[$sel.next_8_bits() as usize] = register1 $x register2;
    };
}

impl VM {
    pub fn new() -> VM {
        VM {
            registers: [0; 32],
            pc: 0,
            program: vec![],
            remainder: 0,
        }
    }

    pub fn run(&mut self) {
        let mut is_done = false;
        while !is_done {
            is_done = self.execute_instruction();
        }
    }

    pub fn run_once(&mut self) {
        self.execute_instruction();
    }

    fn execute_instruction(&mut self) -> bool {
        // If our program counter has exceeded the length of the program
        // itself, something has gone awry
        if self.pc >= self.program.len() {
            return false;
        }
        match self.decode_opcode() {
            Opcode::LOAD => {
                // We cast to usize so we can use it as an index into the array
                let register = self.next_8_bits() as usize;
                let number = self.next_16_bits() as u16;
                // Our registers are i32s, so we need to cast it.
                self.registers[register] = number as i32;
                true
            }
            Opcode::JMP => {
                let target = self.registers[self.next_8_bits() as usize];
                self.pc = target as usize;
                true
            }
            Opcode::ADD => {
                bin_op!(self, +);
                true
            }
            Opcode::SUB => {
                bin_op!(self, -);
                true
            }
            Opcode::MUL => {
                bin_op!(self, *);
                true
            }
            Opcode::DIV => {
                let register1 = self.registers[self.next_8_bits() as usize];
                let register2 = self.registers[self.next_8_bits() as usize];
                self.registers[self.next_8_bits() as usize] = register1 / register2;
                self.remainder = (register1 % register2) as u32;
                true
            }
            Opcode::HLT => {
                println!("HLT encountered");
                false
            }
            _ => {
                println!("Undefined opcode found");
                false
            }
        }
    }

    fn decode_opcode(&mut self) -> Opcode {
        let opcode = Opcode::from(self.program[self.pc]);
        self.pc += 1;
        return opcode;
    }

    fn next_8_bits(&mut self) -> u8 {
        let result = self.program[self.pc];
        self.pc += 1;
        return result;
    }

    fn next_16_bits(&mut self) -> u16 {
        let result = ((self.program[self.pc] as u16) << 8) | self.program[self.pc + 1] as u16;
        self.pc += 2;
        return result;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_vm() {
        let test_vm = VM::new();
        assert_eq!(test_vm.registers[0], 0)
    }

    #[test]
    fn test_load_opcode() {
        let mut test_vm = VM::new();
        // Remember, this is how we represent 500 using two u8s in little endian format
        test_vm.program = vec![0, 0, 1, 244];
        test_vm.run_once();
        assert_eq!(test_vm.registers[0], 500);
    }

    #[test]
    fn test_jmp_opcode() {
        let mut test_vm = VM::new();
        test_vm.registers[0] = 1;
        test_vm.program = vec![7, 0, 0, 0];
        test_vm.run_once();
        assert_eq!(test_vm.pc, 1);
    }

    #[test]
    fn test_opcode_hlt() {
        let mut test_vm = VM::new();
        let test_bytes = vec![0, 0, 0, 0];
        test_vm.program = test_bytes;
        test_vm.run_once();
        assert_eq!(test_vm.pc, 1);
    }

    #[test]
    fn test_opcode_igl() {
        let mut test_vm = VM::new();
        let test_bytes = vec![200, 0, 0, 0];
        test_vm.program = test_bytes;
        test_vm.run_once();
        assert_eq!(test_vm.pc, 1);
    }
}
