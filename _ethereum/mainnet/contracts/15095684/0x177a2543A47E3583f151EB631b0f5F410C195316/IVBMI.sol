// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IERC20PermitUpgradeable.sol";

import "./IERC20Upgradeable.sol";

interface IVBMI is IERC20Upgradeable, IERC20PermitUpgradeable {
    function slashUserTokens(address user, uint256 amount) external;
}
