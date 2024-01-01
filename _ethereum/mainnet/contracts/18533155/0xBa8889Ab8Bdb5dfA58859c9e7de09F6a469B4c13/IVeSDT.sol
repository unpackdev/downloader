// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IveSDT {
    function create_lock(uint256, uint256) external;

    function withdraw() external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256) external;
}