---
created: 250702 09:21:06
updated: 250702 09:24:21
---
# Rust Workshop Resume - Chapter 3: Common Programming Concepts
**Date: July 5, 2025**

## Overview
This chapter introduces fundamental programming concepts in Rust: variables and mutability, data types, functions, comments, and control flow. These concepts form the foundation for all Rust programs and demonstrate Rust's unique approach to memory safety and performance.

---

## 1. Discussion Section

### Core Topics for Deep Exploration

**1.1 The Philosophy of Mutability in Rust**
- Why does Rust make variables immutable by default?
- How does this design choice relate to Rust's memory safety guarantees?
- Compare Rust's approach to mutability with other languages you know
- Discuss the trade-offs between safety and convenience

**1.2 Rust's Type System Design**
- How do Rust's scalar and compound types differ from other languages?
- What makes Rust's approach to integer overflow unique?
- Why does Rust have both `String` and `&str`? What problems does this solve?
- Explore the concept of "zero-cost abstractions" in Rust's type system

**1.3 Function Design and Ownership Preview**
- How do Rust functions handle parameters differently than other languages?
- What is the significance of the distinction between statements and expressions?
- Why does Rust require explicit return types for some functions but not others?
- How does function design in Rust promote code clarity and safety?

**1.4 Control Flow and Pattern Matching Philosophy**
- How does Rust's `if` as an expression change how we think about conditionals?
- What advantages does pattern matching provide over traditional switch statements?
- How do Rust's loop constructs promote both safety and performance?

### Discussion Questions
1. How does Rust's "immutable by default" philosophy change your approach to problem-solving?
2. What are the implications of Rust's strict type system for team collaboration?
3. How might Rust's expression-based syntax influence code readability and maintainability?
4. In what scenarios would you choose different loop types (`loop`, `while`, `for`)?

---

## 2. Quiz Section

### Knowledge Check Questions

**2.1 Variables and Mutability (10 points)**

1. What is the output of this code?
```rust
let x = 5;
let x = x + 1;
let x = x * 2;
println!("{}", x);
```
a) Compilation error  b) 5  c) 12  d) 10

2. Which statement about constants is correct?
a) Constants can be declared in any scope
b) Constants must always have type annotations
c) Constants can be set to function call results
d) Both a and b are correct

3. What's the difference between shadowing and mutability?

**2.2 Data Types (15 points)**

4. What is the default integer type in Rust?
a) i32  b) i64  c) u32  d) usize

5. Which of these will cause a compilation error?
```rust
let tup: (i32, f64, u8) = (500, 6.4, 1);
let (x, y, z) = tup;
let five_hundred = tup.0;
let one = tup.3;  // This line
```

6. What's the difference between arrays and vectors in Rust?

**2.3 Functions (10 points)**

7. What will this function return?
```rust
fn mystery_function(x: i32) -> i32 {
    x + 1;
}
```
a) x + 1  b) ()  c) Compilation error  d) x

8. Which is a valid function signature?
a) `fn add(x: i32, y: i32) -> i32`
b) `fn add(x, y) -> i32`
c) `fn add(x: i32, y: i32): i32`
d) `function add(x: i32, y: i32) -> i32`

**2.4 Control Flow (15 points)**

9. What's the value of `number` after this code?
```rust
let condition = true;
let number = if condition { 5 } else { 6 };
```

10. Which loop will execute exactly 5 times?
a) `for i in 0..5`  b) `for i in 0..=5`  c) `for i in 1..5`  d) `for i in 1..=5`

### Answer Key
1. c) 12  2. d) Both a and b  3. [Open answer about shadowing creating new variables vs mutating existing ones]  4. a) i32  5. The line `let one = tup.3;` - tuples are zero-indexed  6. [Open answer about fixed size vs dynamic size]  7. c) Compilation error - missing return  8. a)  9. 5  10. a) `for i in 0..5`

---

## 3. Challenge Section

### Practical Exercises to Master Chapter 3 Concepts

**Challenge 3.1: Temperature Converter (Beginner)**
Create a program that converts temperatures between Celsius, Fahrenheit, and Kelvin.

Requirements:
- Use functions for each conversion
- Handle user input
- Use appropriate data types
- Implement proper error handling for invalid inputs

```rust
// Starter template
fn celsius_to_fahrenheit(celsius: f64) -> f64 {
    // Your implementation here
}

fn main() {
    // Your implementation here
}
```

**Challenge 3.2: Number Guessing Game Enhancement (Intermediate)**
Extend the guessing game from Chapter 2 with these features:

Requirements:
- Add difficulty levels (easy: 1-10, medium: 1-50, hard: 1-100)
- Track number of attempts
- Provide hints (higher/lower, hot/cold)
- Allow multiple rounds
- Keep score across rounds

**Challenge 3.3: Simple Calculator (Intermediate)**
Build a calculator that can perform basic arithmetic operations.

Requirements:
- Support +, -, *, / operations
- Handle division by zero
- Use match expressions for operation selection
- Support floating-point numbers
- Implement a loop for continuous calculations

**Challenge 3.4: Fibonacci Sequence Generator (Advanced)**
Create a program that generates Fibonacci sequences using different approaches.

Requirements:
- Implement iterative version
- Implement recursive version (if possible with current knowledge)
- Compare performance between approaches
- Handle large numbers appropriately
- Allow user to specify sequence length

### Success Criteria
- Code compiles without warnings
- Proper use of Rust idioms covered in Chapter 3
- Clear, readable code with appropriate comments
- Handles edge cases gracefully
- Demonstrates understanding of ownership basics

---

## 4. Homework Section

### Advanced Coding Challenges

**Homework 4.1: Advanced Pattern Matching System**
Create a comprehensive pattern matching system for a simple text adventure game.

**Specifications:**
- Design an enum for different game states (Menu, Playing, Inventory, GameOver)
- Implement a command parser that matches user input to actions
- Use nested match expressions for complex game logic
- Handle invalid commands gracefully
- Implement a simple inventory system using arrays/tuples

**Technical Requirements:**
- Minimum 5 different commands
- At least 3 game states
- Use of compound data types (tuples, arrays)
- Proper error handling
- Code documentation

**Homework 4.2: Memory-Efficient Data Processor**
Build a data processing system that demonstrates advanced understanding of Rust's type system.

**Specifications:**
- Process a dataset of student records (name, age, grades)
- Calculate statistics (average, median, mode) for grades
- Implement data validation with custom error types
- Use appropriate data structures for efficiency
- Handle large datasets without unnecessary memory allocation

**Technical Requirements:**
- Custom struct definitions
- Implementation of multiple calculation functions
- Proper use of references where appropriate
- Error handling for invalid data
- Performance considerations in algorithm choice

**Homework 4.3: Control Flow Optimization Challenge**
Create a program that solves the "Collatz Conjecture" problem with multiple implementation approaches.

**Specifications:**
- Implement the Collatz sequence calculation
- Compare iterative vs functional approaches
- Track and analyze performance metrics
- Handle potential integer overflow
- Visualize results (simple text-based graphs)

**Technical Requirements:**
- Multiple algorithm implementations
- Performance measurement and comparison
- Proper handling of edge cases
- Clear documentation of approach differences
- Analysis of results and recommendations

### Submission Guidelines
- All code must compile with `cargo check`
- Include comprehensive comments explaining your approach
- Provide test cases for your functions
- Write a brief reflection (200-300 words) on what you learned
- Demonstrate creativity while adhering to Rust best practices

### Evaluation Criteria
- **Correctness (40%)**: Code works as specified
- **Rust Idioms (25%)**: Proper use of Rust language features
- **Code Quality (20%)**: Readability, organization, comments
- **Innovation (15%)**: Creative solutions and additional features

---

## Learning Objectives Achieved
By completing this workshop, participants will:
- Understand Rust's approach to variable mutability and its safety implications
- Master Rust's type system and appropriate type selection
- Write clear, expressive functions following Rust conventions
- Implement complex control flow using Rust's expression-based syntax
- Apply these concepts to solve real-world programming problems
- Develop confidence in autonomous problem-solving with Rust

## Next Steps
- Review ownership concepts (preparation for Chapter 4)
- Practice with more complex data structures
- Explore Rust's standard library documentation
- Begin thinking about memory management concepts

---

**Workshop Facilitator Notes:**
- Encourage pair programming during challenges
- Emphasize the "why" behind Rust's design decisions
- Connect concepts to real-world software engineering problems
- Foster discussion about trade-offs in language design
- Promote autonomous learning through exploration and experimentation
