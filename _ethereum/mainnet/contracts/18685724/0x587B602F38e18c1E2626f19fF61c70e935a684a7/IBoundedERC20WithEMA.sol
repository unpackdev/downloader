// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "IERC20Upgradeable.sol";

interface IBoundedERC20WithEMA is IERC20Upgradeable {
    function boundedPctEMA() external view returns (uint256);
}
