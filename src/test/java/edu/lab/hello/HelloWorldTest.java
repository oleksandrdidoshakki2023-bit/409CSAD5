package edu.lab.hello;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class HelloWorldTest {
    @Test
    void returnsExpectedGreeting() {
        assertEquals("Hello, World!", HelloWorld.greeting());
    }
}
