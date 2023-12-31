// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./basic.sol";

contract Events is Basic {
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
}
