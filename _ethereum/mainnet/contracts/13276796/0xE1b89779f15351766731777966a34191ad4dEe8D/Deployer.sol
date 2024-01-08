pragma solidity ^0.8.0;

import "./forbitspace.sol";


contract Deployer {

    address public result;
    address public owner;

    modifier onlyDeployerOwner() {
        require(owner == msg.sender, "FORBIDEN");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deploy(bytes32 salt) public onlyDeployerOwner {
        bytes memory bytecode = type(forbitspace).creationCode;
        address addr;

        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        result = addr;
    }

    function transferOwner(address _newOwner) public onlyDeployerOwner {
        forbitspace(result).changeOwner(_newOwner);
    }
}