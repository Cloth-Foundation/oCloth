# Cloth Factory Demo

This is a second Cloth example project built against the updated draft spec.
It leans harder into:

- single inheritance via `:>`
- interfaces
- factory methods returning owned instances
- `override`
- base-constructor chaining with `: base(...)`
- owned, borrowed, and shared-ish style interactions where practical
- deterministic destruction

## Notes

Because the Cloth spec is still evolving, a few syntax choices here are best-effort:

- interface member declaration style
- abstract/prototype member spelling
- override spelling and placement

The example stays as close as possible to the updated draft sections covering classes,
interfaces, inheritance, factories, ownership, and destruction.
