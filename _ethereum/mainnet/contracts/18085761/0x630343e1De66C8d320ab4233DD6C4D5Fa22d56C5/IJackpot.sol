// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IJackpot {
    function deposit(address, uint) external;

    function withdraw() external;
}
