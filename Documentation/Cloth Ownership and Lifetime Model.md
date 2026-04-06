# Cloth Ownership & Lifetime Model

Cloth uses an **exclusive instance ownership model** based on object relationships.

All instance objects exist within an **acyclic ownership hierarchy** rooted at program startup.

* Each object may exclusively own other **object instances**
* Ownership is established between **instances**, not types
* Ownership forms an **acyclic graph with single parentage**
* Destruction is **deterministic and cascading**
* `static` members exist in a **separate root-lifetime domain** outside instance ownership
* Cloth distinguishes between **owned**, **referenced**, and **shared** relationships

This model removes the need for a traditional garbage collector while still providing structured, predictable, and explicit memory management.

---

## Core Concepts

### Relationship Markers

Cloth expresses object relationship semantics through type forms.

```cloth
Type    // owned
&Type   // non-owning reference
$Type   // shared / managed
````

These type forms indicate how a value participates in lifetime management.

#### `Type` — Owned by Default

An unprefixed object type is an **owned instance**.

```cloth
private Renderer renderer;
```

* Ownership is exclusive
* The containing storage domain is responsible for destruction
* Owned instances participate in the acyclic ownership hierarchy
* An owned instance may be transferred, but may not have multiple owners at once

Ownership is inferred from the declaration context:

* A field of type `Type` is owned by the containing object
* A local of type `Type` is owned by the containing scope
* A parameter of type `Type` is an owned input to the function unless otherwise specified
* A return value of type `Type` returns ownership to the caller

This keeps ownership explicit as a language rule without requiring an ownership marker on every declaration.

#### `&Type` — Non-Owning Reference

An `&Type` is a **non-owning reference** to an object.

```cloth
private &Renderer rendererRef;
```

* Does not affect lifetime
* Does not keep the referenced object alive
* May point to an object owned elsewhere
* Exists to express object relationships without introducing ownership

#### `$Type` — Shared / Managed

A `$Type` is a **shared or managed object relationship**.

```cloth
private $Texture texture;
```

* Not exclusively owned by a single instance
* Intended for objects that must exist across ownership boundaries
* May be implemented through a managed runtime strategy such as reference counting or another shared-lifetime mechanism
* Exists for cases where exclusive ownership is not the correct lifetime model

---

### Instance Ownership

Ownership in Cloth is based on **runtime object instances**, not on class relationships.

An object may own zero or more child instances.
Those children may in turn own their own child instances, forming an ownership hierarchy.

Example:

```text
Main
 └── App
      └── Window
           └── Renderer
```

Each object is responsible for the lifetime of the instances it owns.

---

### Ownership Applies to Instances, Not Types

Ownership does **not** impose restrictions on which types may appear in the ownership chain.

This is valid:

```text
A instance
 └── B instance
      └── A instance
```

Because the owned `A` is a **different instance** from the original `A`.

What Cloth forbids is not repeated types, but **ownership cycles between instances**.

This is invalid:

```text
A instance
 └── B instance
      └── A instance (the original owner)
```

In other words:

* Type repetition is allowed
* Instance ownership cycles are not

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

* `Main` acts as the **root of the dynamic ownership domain**
* All instance objects exist directly or indirectly under `Main`, unless placed in another lifetime domain
* Program lifetime is defined by the lifetime of `Main`

---

## Ownership Rules

### 1. Exclusive Instance Ownership

Each owned instance may have **at most one owner**.

```cloth
private Renderer renderer;
```

* Ownership is exclusive unless explicitly transferred
* An owned object cannot belong to multiple owners at the same time

---

### 2. Ownership is Runtime Structural

If object instance `A` owns object instance `B`, then `B` is part of `A`’s lifetime domain.

* When `A` is destroyed, `B` is also destroyed
* Ownership is based on actual object relationships at runtime
* Ownership is not inferred from inheritance or type similarity

---

### 3. Acyclic Ownership Only

Ownership must remain **acyclic**.

This means an object may never directly or indirectly own itself.

Invalid examples:

```text
A -> A
A -> B -> A
A -> B -> C -> A
```

If an ownership transfer or assignment would create a cycle, it is invalid.

---

### 4. No Implicit Global Ownership

There is no user-visible global heap owner.

* Ownership is always tied to an object instance or scope
* The program root is established through `Main`
* Static storage is handled separately

---

### 5. Ownership May Be Transferred

Ownership is not fixed forever.

An owned instance may be transferred from one owner to another, provided:

* it has only one owner at a time
* the transfer does not create an ownership cycle
* the runtime ownership structure remains valid

This allows dynamic object composition without requiring a garbage collector.

---

### 6. References Do Not Own

A non-owning reference does not participate in ownership.

```cloth
private &Renderer rendererRef;
```

* A reference may point to an owned or shared object
* A reference does not make the target part of the referencing object’s lifetime domain
* Referencing and ownership are separate concepts

---

### 7. Shared Objects Exist Outside Exclusive Ownership

Some objects are not well represented by exclusive single-owner lifetime rules.

```cloth
private $Texture cachedTexture;
```

* Shared objects may outlive any one owner
* Shared objects are intended for cases such as caches, asset handles, or cross-domain resources
* Shared relationships exist to complement ownership, not replace it

---

## Static Lifetime Domain (Exception Rule)

Static members in Cloth are globally accessible and exist for the entire duration of the program.

They **do not participate in instance ownership** and are **not owned by any object instance**.

Instead, they exist in a **root-lifetime domain** that runs alongside the dynamic ownership hierarchy.

```cloth
public class Example {

    public static const i32 value = 10;

}
```

Conceptually:

* Instance data → owned, referenced, or shared through object relationships
* Static data → exists for the entire program lifetime

---

## Lifetime Domains

Cloth separates memory into distinct lifetime domains:

### 1. Ownership Domain (Dynamic)

* Rooted at `Main`
* Contains all exclusively owned instance objects
* Ownership is exclusive and acyclic
* Objects are created, transferred, and destroyed
* Destruction is cascading and deterministic

### 2. Shared Domain (Managed)

* Contains objects represented through `$Type`
* Not governed by exclusive parent-child ownership
* Intended for objects whose lifetime must cross ownership boundaries
* Managed by a separate shared-lifetime strategy

### 3. Static Domain (Root Lifetime)

* Exists for the duration of the program
* Not part of instance ownership
* Not owned or transferred
* Effectively always alive

---

## Destruction Model

### Deterministic Destruction

Cloth uses **deterministic destruction** for owned objects.

When an owned object is destroyed:

1. Its owned children are destroyed recursively
2. Its destructor is executed

This guarantees predictable cleanup and avoids garbage collection pauses in the ownership domain.

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

    private Renderer renderer;
    private &Renderer debugRenderer;
    private $Texture texture;

    public Engine(Renderer renderer, $Texture texture) {
        this.renderer = renderer;
        this.debugRenderer = renderer;
        this.texture = texture;
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

```text
Renderer destroyed
Engine shutting down
```

* Owned children are destroyed before the parent completes destruction
* Non-owning references do not affect destruction
* Shared objects are not destroyed through exclusive ownership rules unless their own management strategy requires it

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

Defines lifetime relationships between instances:

```cloth
private Child child;
```

### Reference

Defines access without lifetime control:

```cloth
private &Child childRef;
```

* A parent class does **not** own its subclasses by virtue of inheritance
* An object owns only the specific instances it creates, receives, or stores as owned children
* Referencing a type does not imply ownership of that type

---

## Null Safety & Ownership Interaction

Cloth enforces null-awareness through explicit typing and operators.

```cloth
const i32 value = getMyInt() ?? 0;
```

Relationship markers compose naturally with nullability:

```cloth
Renderer? renderer;
&Node? parent;
$Texture? cache;
```

* `??` provides a fallback value
* Prevents unsafe dereferencing
* Ownership, reference, and shared semantics remain explicit even when nullable

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

Cloth avoids GC in its ownership domain to provide:

* Deterministic destruction
* Predictable performance
* Explicit control over object lifetime

---

### Why Default-Owned Types?

Making unprefixed object types owned by default provides:

* Cleaner syntax
* A natural Java-like declaration style
* Explicit lifetime semantics through a simple language rule
* Less noise than requiring an ownership marker on every declaration

Ownership inference in Cloth is intentionally narrow:

* It is inferred from the storage domain
* It is not broad compiler magic
* It does not change the acyclic ownership model

---

### Why Distinguish Owned, Referenced, and Shared?

Not every object relationship is an ownership relationship.

Separating these concepts provides:

* Clear lifetime semantics
* Better modeling of real programs
* The ability to reference objects without claiming responsibility for their destruction
* A structured escape hatch for resources that cannot fit cleanly into single-owner hierarchies

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