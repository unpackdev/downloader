/// SPDX-License-Identifier: BUSL-1.1

/// Copyright (C) 2023 Brahma.fi

pragma solidity 0.8.19;

import "./IAddressProviderService.sol";
import "./AddressProvider.sol";
import "./Constants.sol";

/**
 * @title AddressProviderService
 * @author Brahma.fi
 * @notice Provides a base contract for services to resolve other services through AddressProvider
 * @dev This contract is designed to be inheritable by other contracts
 *  Provides quick and easy access to all contracts in Console Ecosystem
 */
abstract contract AddressProviderService is IAddressProviderService, Constants {
    error InvalidAddressProvider();
    error NotGovernance(address);
    error InvalidAddress();

    /// @notice address of addressProvider
    // solhint-disable-next-line immutable-vars-naming
    AddressProvider public immutable addressProvider;
    address public immutable walletRegistry;
    address public immutable policyRegistry;
    address public immutable executorRegistry;

    constructor(address _addressProvider) {
        if (_addressProvider == address(0)) revert InvalidAddressProvider();
        addressProvider = AddressProvider(_addressProvider);

        walletRegistry = addressProvider.getRegistry(_WALLET_REGISTRY_HASH);
        policyRegistry = addressProvider.getRegistry(_POLICY_REGISTRY_HASH);
        executorRegistry = addressProvider.getRegistry(_EXECUTOR_REGISTRY_HASH);

        _notNull(walletRegistry);
        _notNull(policyRegistry);
        _notNull(executorRegistry);
    }

    /**
     * @inheritdoc IAddressProviderService
     */
    function addressProviderTarget() external view override returns (address) {
        return address(addressProvider);
    }

    /**
     * @notice Helper to get authorized address from address provider
     * @param _key keccak256 key corresponding to authorized address
     * @return authorizedAddress
     */
    function _getAuthorizedAddress(bytes32 _key) internal view returns (address authorizedAddress) {
        authorizedAddress = addressProvider.getAuthorizedAddress(_key);
        _notNull(authorizedAddress);
    }

    /**
     * @notice Helper to revert if address is null
     * @param _addr address to check
     */
    function _notNull(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }
}
