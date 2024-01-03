// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

contract Seed {
    address public deployer;
    address public implementation;

    constructor() {
        deployer = msg.sender;
    }

    function changeDeployer(address newDeployer) external {
        require(msg.sender == deployer);
        deployer = newDeployer;
    }

    function changeImplementation(address newImplementation) external {
        require(msg.sender == deployer);
        implementation = newImplementation;
    }
}