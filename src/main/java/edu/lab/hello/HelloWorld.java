package edu.lab.hello;

public final class HelloWorld {
    private HelloWorld() {
    }

    public static String greeting() {
        return "Hello, World!";
    }

    public static void main(String[] args) {
        System.out.println(greeting());
    }
}
