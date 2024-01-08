// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Address.sol";
import "./IRegistry.sol";

/// @title Oh! Finance Registry
/// @dev Contract that contains references to the all core contracts for Oh! Finance
/// @dev Ideally, we should never need to replace this contract. Only update references.
contract OhRegistry is IRegistry {
    using Address for address;

    /// @notice address of governance contract
    address public override governance;
    /// @notice address of the management contract
    address public override manager;

    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event ManagerUpdated(address indexed oldManager, address indexed newManager);

    modifier onlyGovernance {
        require(msg.sender == governance, "Registry: Only Governance");
        _;
    }

    constructor() {
        governance = msg.sender;
    }

    /// @notice Sets the Governance address
    /// @param _governance the new governance address
    /// @dev Only Governance can call this function
    function setGovernance(address _governance) external onlyGovernance {
        require(_governance.isContract(), "Registry: Invalid Governance");
        emit GovernanceUpdated(governance, _governance);
        governance = _governance;
    }

    /// @notice Sets the Manager address
    /// @param _manager the new manager address
    /// @dev Only Governance can call this function
    function setManager(address _manager) external onlyGovernance {
        require(_manager.isContract(), "Registry: Invalid Manager");
        emit ManagerUpdated(manager, _manager);
        manager = _manager;
    }
}
