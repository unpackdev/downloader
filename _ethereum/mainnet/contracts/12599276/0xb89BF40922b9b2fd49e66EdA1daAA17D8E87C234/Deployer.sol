pragma solidity ^0.8.0;

contract Deployer {
    function deploy(bytes memory bytecode, bytes32 salt) external {
        address addr;
        
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }
}