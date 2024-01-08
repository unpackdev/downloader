// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./XenoERC20Store.sol";

/* STORAGE */

contract ERC20Storage {
    XenoERC20Store internal x;
    uint256[50] private ______gap;
}