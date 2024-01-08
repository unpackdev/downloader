// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}
