// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Cloner.sol";
import "./ECDSA.sol";

contract MonaArtistContractFactory {

    address public implementation;
    address public owner;

    event Cloned(address indexed instance);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _implementation) {
        implementation = _implementation;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        delete owner;
    }
    
    function setImplementation(address newImplementation) external {
        require(bytes2(bytes20(newImplementation)) == bytes2(0), "Must be a vanity address!");
        implementation = newImplementation;
    }


    function clone(bytes calldata signature) external payable {
        require(owner == ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender))), signature));

        address instance = Cloner.createClone(implementation);
        
        emit Cloned(instance);
    }

    function getMsgHash(address addr) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

}