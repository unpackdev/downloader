// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function user_checkpoint(address) external;
}
