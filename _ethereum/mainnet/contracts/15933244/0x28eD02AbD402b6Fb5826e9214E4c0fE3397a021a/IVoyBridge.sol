// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVoyBridge {
    function initiateSwap(address _user, uint256 _amount) external;
}