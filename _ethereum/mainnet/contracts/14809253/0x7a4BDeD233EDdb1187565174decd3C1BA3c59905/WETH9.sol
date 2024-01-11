// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "IERC20.sol";

interface WETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}
