// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IStaking {
    function deposit(address, uint) external;

    function withdraw() external;
}
