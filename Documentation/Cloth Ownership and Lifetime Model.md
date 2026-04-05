# Cloth Ownership & Lifetime Model

## Summary

Cloth uses a **hierarchical ownership model** based on object relationships.
All objects exist within an **ownership tree**, rooted at program startup.

* Each object owns its **declared and created children**
* Ownership forms a **tree structure (parent → child)**
* Destruction is **deterministic and cascading**
* `static` members exist in a **separate root-lifetime domain** outside the ownership tree

This model removes the need for a traditional garbage collector while still providing structured and predictable memory management.

---

## Core Concepts

### Ownership Tree

Ownership in Cloth behaves like a **family tree**:

* The program begins with a root object (`Main`)
* Objects created within another object become its **children**
* Children may own their own children, forming a tree

```
Main
 └── App
      └── Window
           └── Renderer
```

Each node is responsible for the lifetime of its descendants.

---

### Root Object

The entry point of a Cloth program is the construction of a `Main` class.

```cloth
module example;

public class Main(String[] args) {

    public Main {
        // entry point
    }

}
```

* `Main` acts as the **root of the ownership tree**
* All program objects exist directly or indirectly under `Main`
* Program lifetime is defined by the lifetime of `Main`

---

### Ownership Rules

1. **Instance Ownership**

   * Objects own their fields and any objects created within their scope
   * Ownership is exclusive unless explicitly transferred

2. **Parent → Child Relationship**

   * If object `A` creates object `B`, then `A` owns `B`
   * When `A` is destroyed, `B` is also destroyed

3. **No Implicit Global Ownership**

   * There is no global heap owner exposed to the user
   * Ownership is always tied to an object

---

### Static Lifetime Domain (Exception Rule)

Static members in Cloth are globally accessible and exist for the entire duration of the program.
They **do not participate in the ownership tree** and are **not owned by any object**.

Instead, they exist in a **root-lifetime domain** that runs alongside the ownership hierarchy.

```cloth
public class Example {

    public static const i32 value = 10;

}
```

Conceptually:

* Instance data → owned by object
* Static data → exists for the entire program lifetime

---

## Lifetime Domains

Cloth separates memory into two distinct lifetime domains:

### 1. Ownership Domain (Dynamic)

* Rooted at `Main`
* Contains all instance objects
* Objects are created and destroyed
* Destruction is cascading and deterministic

### 2. Static Domain (Root Lifetime)

* Exists for the duration of the program
* Not part of the ownership tree
* Not owned or transferred
* Effectively always alive

---

## Destruction Model

### Deterministic Destruction

Cloth uses **deterministic destruction**.

When an object is destroyed:

1. Its destructor is executed
2. All owned children are destroyed recursively

---

### Destructor Syntax

Destructors are declared using the `~ClassName` syntax:

```cloth
public ~Main {
    println("Goodbye, World!");
}
```

* Called automatically when the object is destroyed
* Cannot be called manually
* Used for cleanup (resources, logging, etc.)

---

### Example: Full Program Lifecycle

```cloth
module example;

import cloth.out::{println};

public class Main(String[] args) {

    public Main {
        println("Hello, World!");
    }

    public ~Main {
        println("Goodbye, World!");
    }

    public func run() :> void maybe NaN {
        println("Running...");
    }

}
```

#### Execution Flow

1. Program starts
2. `Main` is constructed

   * `"Hello, World!"` is printed
3. Program executes
4. Program exits
5. `Main` is destroyed

   * `"Goodbye, World!"` is printed

---

### Cascading Destruction Example

```cloth
public class Engine {

    private Renderer renderer { public get; };

    public Engine {
        this.renderer = new Renderer();
    }

    public ~Engine {
        println("Engine shutting down");
    }

}

public class Renderer {

    public ~Renderer {
        println("Renderer destroyed");
    }

}
```

#### Destruction Order

If `Engine` is destroyed:

```
Renderer destroyed
Engine shutting down
```

* Children are destroyed **before** the parent completes destruction
* This ensures safe cleanup

---

## Ownership vs Inheritance

Ownership and inheritance are **separate concepts**.

### Inheritance

Defines type relationships:

```cloth
public class Child :> Parent {
}
```

### Ownership

Defines lifetime relationships:

```cloth
this.child = new Child();
```

* A parent class does **not** own its subclasses
* An object owns only what it **creates or holds**

---

## Null Safety & Ownership Interaction

Cloth enforces null-awareness through explicit typing and operators.

```cloth
const i32 value = getMyInt() ?? 0;
```

* `??` provides a fallback value
* Prevents unsafe dereferencing

Ownership ensures that:

* Valid objects remain alive within their owner’s lifetime
* Null handling is explicit and controlled

---

## Error-Aware Returns (`maybe`)

Functions may declare that they can return errors:

```cloth
public func intToUnsigned() :> u32 maybe NegativeNumberError, NullValueError;
```

* `maybe` indicates non-guaranteed success
* Works alongside ownership and null safety
* Encourages explicit handling of failure paths

---

## Design Rationale

### Why Not a Garbage Collector?

Cloth avoids GC to provide:

* Deterministic destruction
* Predictable performance
* Explicit control over object lifetime

---

### Why a Tree Model?

The ownership tree provides:

* Clear mental model
* No hidden memory behavior
* Natural cleanup via cascading destruction
* Strong alignment with class-based design

---

### Why Static is Not Owned

Static values:

* Exist independently of instances
* Persist for the entire program lifetime
* Do not participate in ownership relationships

Separating static from ownership:

* Prevents confusion about lifetime
* Avoids invalid ownership assumptions
* Keeps the model simple and consistent
