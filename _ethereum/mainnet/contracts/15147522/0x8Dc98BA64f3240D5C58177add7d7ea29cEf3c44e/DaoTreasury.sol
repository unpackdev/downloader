// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Upgradeable} from "Upgradeable.sol";

contract DaoTreasury is Upgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    function initialize(address pauser) external initializer {
        __Upgradeable_init(msg.sender, pauser);
    }

    function transfer(
        IERC20 token,
        address to,
        uint256 amount
    ) public onlyRole(MANAGER_ROLE) whenNotPaused {
        token.safeTransfer(to, amount);
    }

    function approve(
        IERC20 token,
        address spender,
        uint256 amount
    ) public onlyRole(MANAGER_ROLE) whenNotPaused {
        token.approve(spender, amount);
    }
}
