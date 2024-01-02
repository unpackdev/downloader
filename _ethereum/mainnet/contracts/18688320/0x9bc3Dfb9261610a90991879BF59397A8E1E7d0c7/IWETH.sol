// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}
