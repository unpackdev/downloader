// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./AccessControl.sol";

contract AccessManager is AccessControl {
    address public governance;
    address public pendingGovernance;

    // Governance setters
    function setPendingGovernance(address _pendingGovernance)
    external
    onlyGovernance
    {
        pendingGovernance = _pendingGovernance;
    }

    function acceptGovernance() external onlyPendingGovernance {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(
            msg.sender == governance || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only governance can call this function."
        );
        _;
    }

    modifier onlyPendingGovernance() {
        require(
            msg.sender == pendingGovernance,
            "Only pendingGovernance can call this function."
        );
        _;
        pendingGovernance = address(0);
    }

    modifier onlyOwnerOrAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == governance,
            "!only owner or admin user"
        );
        _;
    }
}
