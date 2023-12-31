// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Clones.sol";
import "./DirectDepositWithdraw.sol";

contract DeterministicDeployFactory {
    DirectDepositWithdraw private implementation;
    address private owner;

    constructor() {
        owner = msg.sender;
        implementation = new DirectDepositWithdraw();
    }

    function clone(bytes32 salt) public returns (address instance) {
        require(msg.sender == owner, "Only owner can clone");
        instance = Clones.cloneDeterministic(address(implementation), salt);
        DirectDepositWithdraw(payable(instance)).init(owner);
        return instance;
    }

    function predictDeterministicAddress(bytes32 salt) public view returns (address predicted) {
        return Clones.predictDeterministicAddress(address(implementation), salt, address(this));
    }
}
