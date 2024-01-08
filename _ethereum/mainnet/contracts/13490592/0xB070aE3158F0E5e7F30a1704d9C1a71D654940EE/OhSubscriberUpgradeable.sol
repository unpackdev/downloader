// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Initializable.sol";
import "./Address.sol";
import "./ISubscriber.sol";
import "./IRegistry.sol";
import "./OhUpgradeable.sol";

/// @title Oh! Finance Subscriber Upgradeable
/// @notice Base Oh! Finance upgradeable contract used to control access throughout the protocol
abstract contract OhSubscriberUpgradeable is Initializable, OhUpgradeable, ISubscriber {
    bytes32 private constant _REGISTRY_SLOT = 0x1b5717851286d5e98a28354be764b8c0a20eb2fbd059120090ee8bcfe1a9bf6c;

    /// @notice Only allow authorized addresses (governance or manager) to execute a function
    modifier onlyAuthorized {
        require(msg.sender == governance() || msg.sender == manager(), "Subscriber: Only Authorized");
        _;
    }

    /// @notice Only allow the governance address to execute a function
    modifier onlyGovernance {
        require(msg.sender == governance(), "Subscriber: Only Governance");
        _;
    }

    /// @notice Verify the registry storage slot is correct
    constructor() {
        assert(_REGISTRY_SLOT == bytes32(uint256(keccak256("eip1967.subscriber.registry")) - 1));
    }

    /// @notice Initialize the Subscriber
    /// @param registry_ The Registry contract address
    /// @dev Always call this method in the initializer function for any derived classes
    function initializeSubscriber(address registry_) internal initializer {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");
        _setRegistry(registry_);
    }

    /// @notice Set the Registry for the contract. Only callable by Governance.
    /// @param registry_ The new registry
    /// @dev Requires sender to be Governance of the new Registry to avoid bricking.
    /// @dev Ideally should not be used
    function setRegistry(address registry_) external onlyGovernance {
        _setRegistry(registry_);
        require(msg.sender == governance(), "Subscriber: Bad Governance");
    }

    /// @notice Get the Governance address
    /// @return The current Governance address
    function governance() public view override returns (address) {
        return IRegistry(registry()).governance();
    }

    /// @notice Get the Manager address
    /// @return The current Manager address
    function manager() public view override returns (address) {
        return IRegistry(registry()).manager();
    }

    /// @notice Get the Registry address
    /// @return The current Registry address
    function registry() public view override returns (address) {
        return getAddress(_REGISTRY_SLOT);
    }

    function _setRegistry(address registry_) private {
        setAddress(_REGISTRY_SLOT, registry_);
    }
}
