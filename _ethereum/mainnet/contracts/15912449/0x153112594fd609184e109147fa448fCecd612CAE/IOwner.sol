// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IOwner {
    function owner() external view returns(address);
}