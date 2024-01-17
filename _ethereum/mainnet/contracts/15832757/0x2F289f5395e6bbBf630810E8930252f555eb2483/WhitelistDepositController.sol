// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DepositController} from "DepositController.sol";
import {IAccessControl} from "IAccessControl.sol";

contract WhitelistDepositController is DepositController {
    // mapping(portfolio => mapping(user => isWhitelisted))
    mapping(address => mapping(address => bool)) public isWhitelisted;

    event WhitelistStatusChanged(address indexed portfolio, address indexed user, bool status);

    function setWhitelistStatus(
        address portfolio,
        address user,
        bool status
    ) external {
        require(
            IAccessControl(portfolio).hasRole(IAccessControl(portfolio).MANAGER_ROLE(), msg.sender),
            "WhitelistDepositController: Only portfolio manager can change whitelist status"
        );
        require(isWhitelisted[portfolio][user] != status, "WhitelistDepositController: Cannot set the same status twice");

        isWhitelisted[portfolio][user] = status;
        emit WhitelistStatusChanged(portfolio, user, status);
    }

    // ERC4626 interactions

    function maxDeposit(address receiver) public view override returns (uint256) {
        if (isWhitelisted[msg.sender][receiver]) {
            return super.maxDeposit(receiver);
        } else {
            return 0;
        }
    }

    function maxMint(address receiver) public view override returns (uint256) {
        if (isWhitelisted[msg.sender][receiver]) {
            return super.maxMint(receiver);
        } else {
            return 0;
        }
    }

    function onDeposit(
        address sender,
        uint256 assets,
        address receiver
    ) public view override returns (uint256, uint256) {
        if (isWhitelisted[msg.sender][receiver]) {
            return super.onDeposit(sender, assets, receiver);
        } else {
            return (0, 0);
        }
    }

    function onMint(
        address sender,
        uint256 shares,
        address receiver
    ) public view override returns (uint256, uint256) {
        if (isWhitelisted[msg.sender][receiver]) {
            return super.onMint(sender, shares, receiver);
        } else {
            return (0, 0);
        }
    }
}
