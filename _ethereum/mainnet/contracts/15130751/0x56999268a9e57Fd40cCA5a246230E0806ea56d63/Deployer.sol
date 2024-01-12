contract Deployer {
    address public naddr;
    function deploy(bytes calldata contractBytecode, bytes32 salt) public {
    bytes memory bytecode = contractBytecode;
    address addr;
    assembly {
        addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
    }
    naddr = addr;
    }
}