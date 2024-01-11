// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";

interface IERC20UpgradeableExtended is IERC20Upgradeable {
    function decimals() external view returns(uint8);
}