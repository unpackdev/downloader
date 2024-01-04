// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SwapTokenLocker.sol";

contract SwapTokenLockerFactory {
    event SwapTokenLockerCreated(address admin, address locker);
    mapping(address => address[]) private deployedContracts;
    address[] private allLockers;

    function getLastDeployed(address owner) external view returns(address locker) {
        uint256 length = deployedContracts[owner].length;
        return deployedContracts[owner][length - 1];
    }

    function getAllContracts() external view returns (address[] memory) {
        return allLockers;
    }

    function getDeployed(address owner) external view returns(address[] memory) {
        return deployedContracts[owner];
    }

    function createTokenLocker(address token) external returns (address locker) {
        SwapTokenLocker lockerContract = new SwapTokenLocker(msg.sender, token);
        locker = address(lockerContract);
        deployedContracts[msg.sender].push(locker);
        allLockers.push(locker);
        emit SwapTokenLockerCreated(msg.sender, locker);
    }
}

