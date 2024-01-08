// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INTERFACE INHERITANCE IMPORTS */

import "./ManagerRoleInterface.sol";

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20AllowanceInterface.sol";
import "./IERC20Burnable.sol";

import "./FreezableInterface.sol";
import "./PausableInterface.sol";
import "./RecoverableInterface.sol";

/**
 * @dev Interface for XenoERC20
 */
interface IXenoERC20 is
    ManagerRoleInterface,
    IERC20,
    IERC20Metadata,
    ERC20AllowanceInterface,
    IERC20Burnable,
    FreezableInterface,
    PausableInterface,
    RecoverableInterface
{ }