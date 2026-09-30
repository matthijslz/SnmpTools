enum SnmpWalkMode {
    Default         # Walks the entire MIB tree starting from the specified OID.
    WithinSubtree   # Walks only within the subtree of the specified OID, stopping when the next OID is no longer a child of the base OID.
}