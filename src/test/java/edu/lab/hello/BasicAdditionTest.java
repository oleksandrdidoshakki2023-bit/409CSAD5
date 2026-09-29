package edu.lab.hello;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class BasicAdditionTest {
    @Test
    void addsTwoIntegers() {
        assertEquals(5, BasicAddition.add(2, 3));
    }
}
