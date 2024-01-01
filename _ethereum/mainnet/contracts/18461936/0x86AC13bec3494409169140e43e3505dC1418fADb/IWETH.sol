// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IWETH {
    /* ----- Functions ----- */

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
