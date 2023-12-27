/// SPDX-License-Identifier: BUSL-1.1

/// Copyright (C) 2023 Brahma.fi

pragma solidity 0.8.19;

import "./IAddressProviderService.sol";
import "./Constants.sol";

/**
 * @title AddressProvider
 * @author Brahma.fi
 * @notice Single source of truth for resolving addresses of core components and external contracts
 */
contract AddressProvider is Constants {
    error RegistryAlreadyExists();
    error AddressProviderUnsupported();
    error NotGovernance(address);
    error NotPendingGovernance(address);
    error NullAddress();

    event RegistryInitialised(address indexed registry, bytes32 indexed key);
    event AuthorizedAddressInitialised(address indexed authorizedAddress, bytes32 indexed key);
    event GovernanceTransferRequested(address indexed previousGovernance, address indexed newGovernance);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /// @notice address of governance
    address public governance;
    /// @notice address of pending governance before accepting
    address public pendingGovernance;

    /**
     * @notice keccak256 hash of authorizedAddress keys mapped to their addresses
     * @dev Core & Roles are used as keys for this mapping. These addresses are mutable
     * @dev authorizedAddresses are updatable by governance
     */
    mapping(bytes32 => address) internal authorizedAddresses;

    /**
     * @notice keccak256 hash of registry keys mapped to their addresses
     * @dev registries are only set once by governance and immutable
     */
    mapping(bytes32 => address) internal registries;

    constructor(address _governance, address walletRegistry, address policyRegistry, address executorRegistry) {
        _notNull(_governance);
        governance = _governance;

        _notNull(walletRegistry);
        _notNull(policyRegistry);
        _notNull(executorRegistry);
        registries[_WALLET_REGISTRY_HASH] = walletRegistry;
        registries[_POLICY_REGISTRY_HASH] = policyRegistry;
        registries[_EXECUTOR_REGISTRY_HASH] = executorRegistry;
    }

    /**
     * @notice Governance setter
     * @param _newGovernance address of new governance
     */
    function setGovernance(address _newGovernance) external {
        _notNull(_newGovernance);
        _onlyGov();
        emit GovernanceTransferRequested(governance, _newGovernance);
        pendingGovernance = _newGovernance;
    }

    /**
     * @notice Governance accepter
     */
    function acceptGovernance() external {
        if (msg.sender != pendingGovernance) {
            revert NotPendingGovernance(msg.sender);
        }
        emit GovernanceTransferred(governance, msg.sender);
        governance = msg.sender;
        delete pendingGovernance;
    }

    /**
     * @notice Authorized address setter
     * @param _key key of authorizedAddress
     * @param _authorizedAddress address to set
     * @param _overrideCheck overrides check for supported address provider
     */
    function setAuthorizedAddress(bytes32 _key, address _authorizedAddress, bool _overrideCheck) external {
        _onlyGov();
        _notNull(_authorizedAddress);

        /// @dev skips checks for supported `addressProvider()` if `_overrideCheck` is true
        if (!_overrideCheck) {
            /// @dev skips checks for supported `addressProvider()` if `_authorizedAddress` is an EOA
            if (_authorizedAddress.code.length != 0) _ensureAddressProvider(_authorizedAddress);
        }

        authorizedAddresses[_key] = _authorizedAddress;

        emit AuthorizedAddressInitialised(_authorizedAddress, _key);
    }

    /**
     * @notice Registry address setter
     * @param _key key of registry address
     * @param _registry address to set
     */
    function setRegistry(bytes32 _key, address _registry) external {
        _onlyGov();
        _ensureAddressProvider(_registry);

        if (registries[_key] != address(0)) revert RegistryAlreadyExists();
        registries[_key] = _registry;

        emit RegistryInitialised(_registry, _key);
    }

    /**
     * @notice Authorized address getter
     * @param _key key of authorized address
     * @return address of authorized address
     */
    function getAuthorizedAddress(bytes32 _key) external view returns (address) {
        return authorizedAddresses[_key];
    }

    /**
     * @notice Registry address getter
     * @param _key key of registry address
     * @return address of registry address
     */
    function getRegistry(bytes32 _key) external view returns (address) {
        return registries[_key];
    }

    /**
     * @notice Ensures that the new address supports the AddressProviderService interface
     * and is pointing to this AddressProvider
     * @param _newAddress address to check
     */
    function _ensureAddressProvider(address _newAddress) internal view {
        if (IAddressProviderService(_newAddress).addressProviderTarget() != address(this)) {
            revert AddressProviderUnsupported();
        }
    }

    /**
     * @notice Checks if msg.sender is governance
     */
    function _onlyGov() internal view {
        if (msg.sender != governance) revert NotGovernance(msg.sender);
    }

    /**
     * @notice Checks and reverts if address is null
     * @param addr address to check if null
     */
    function _notNull(address addr) internal pure {
        if (addr == address(0)) revert NullAddress();
    }
}
