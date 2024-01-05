// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

/**
 * @title DoughEscrow interface
*/
interface IRewardEscrow {
    function balanceOf(address account) external view returns (uint);
    function appendVestingEntry(address account, uint quantity) external;
}