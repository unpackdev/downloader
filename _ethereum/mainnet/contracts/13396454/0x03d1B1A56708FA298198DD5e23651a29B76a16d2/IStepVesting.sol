// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStepVesting {
    function receiver() external returns (address);
    function claim() external;
}
