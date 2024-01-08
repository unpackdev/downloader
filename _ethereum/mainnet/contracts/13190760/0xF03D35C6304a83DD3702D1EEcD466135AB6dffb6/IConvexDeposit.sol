// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IConvexDeposit{
    function depositAll(uint256 _pid, bool _stake) external; 
}