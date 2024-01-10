// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IERC20Decimals is IERC20Upgradeable {
    function decimals() external returns (uint8);
}
