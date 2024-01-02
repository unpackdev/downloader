// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IOperatorFilterRegistry.sol";

import "./OwnableUpgradeable.sol";

/**
 * @title  MarketplaceFiltererAbridged
 * @notice Abstract contract whose constructor automatically registers and subscribes to default
           subscription from OpenSea, if a valid registry is passed in. 
           Modified from `OperatorFilterer` contract by ishan@ highlight.xyz.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract MarketplaceFiltererAbridged is OwnableUpgradeable {
    error NotAContract();

    error OperatorNotAllowed();

    /**
     * @notice MarketplaceFilterer Registry (CORI)
     */
    address private constant _MARKETPLACE_FILTERER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);

    /**
     * @notice Default subscription to register collection with on CORI Marketplace filterer registry
     */
    address private constant _DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    /**
     * @notice CORI Marketplace filterer registry. Set to address(0) when not used to avoid extra inter-contract calls.
     */
    address public operatorFiltererRegistry;

    function __MarketplaceFilterer__init__(bool useFilterer) internal onlyInitializing {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (useFilterer) {
            _setRegistryAndSubscription(_MARKETPLACE_FILTERER_REGISTRY, _DEFAULT_SUBSCRIPTION);
        }
    }

    /**
     * @notice Update the address that the contract will make MarketplaceFilterer checks against.
     *         Also register this contract with that registry.
     */
    function setRegistryAndSubscription(address newRegistry, address subscription) external onlyOwner {
        _setRegistryAndSubscription(newRegistry, subscription);
    }

    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (operatorFiltererRegistry != address(0)) {
            if (!IOperatorFilterRegistry(operatorFiltererRegistry).isOperatorAllowed(address(this), operator)) {
                _revert(OperatorNotAllowed.selector);
            }
        }
    }

    function _setRegistryAndSubscription(address newRegistry, address subscription) private {
        operatorFiltererRegistry = newRegistry;
        if (newRegistry != address(0)) {
            if (newRegistry.code.length == 0) {
                _revert(NotAContract.selector);
            }
            IOperatorFilterRegistry(newRegistry).registerAndSubscribe(address(this), subscription);
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure virtual {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
