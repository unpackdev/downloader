// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() payable external;
    function withdraw(uint wad) external;
}
