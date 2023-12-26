pragma solidity ^0.8.11;

import "./IERC20.sol";

/**
 * @title Vault
 * @dev Burnable token interface
 * @author Gains Associates
 * SPDX-License-Identifier: GPL-3.0
 */

interface IBurnableERC20 is IERC20 {
    function burn(uint256 amount) external;
}