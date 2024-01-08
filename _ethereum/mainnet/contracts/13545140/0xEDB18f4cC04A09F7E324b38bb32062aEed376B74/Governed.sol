// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Governance.sol";

/**
 * @title Provides permission check modifiers for child contracts
 */
abstract contract Governed {

    // Governance contract
    Governance public immutable governance;

    /**
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor (address governanceAddress) {
        governance = Governance(governanceAddress);
    }

    /**
     * @dev Throws if given address that doesn't have ManagesDeaths permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canManageDeaths(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.ManageDeaths),
            "Governance: subject is not allowed to manage deaths"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have Configure permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canConfigure(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.Configure),
            "Governance: subject is not allowed to configure contracts"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have Bootstrap permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canBootstrap(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.Bootstrap),
            "Governance: subject is not allowed to bootstrap"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have SetOwnerAddress permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canSetOwnerAddress(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.SetOwnerAddress),
            "Governance: subject is not allowed to set owner address"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have TriggerOwnerWithdraw permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canTriggerOwnerWithdraw(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.TriggerOwnerWithdraw),
            "Governance: subject is not allowed to trigger owner withdraw"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have StopPayouyts permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canStopPayouts(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.StopPayouts),
            "Governance: subject is not allowed to stop payouts"
        );
        _;
    }
}
