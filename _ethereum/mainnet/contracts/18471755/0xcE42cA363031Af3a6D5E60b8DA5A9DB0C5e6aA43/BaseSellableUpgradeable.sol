// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./ISellable.sol";
import "./SteerableAccessControlEnumerableUpgradeable.sol";

/**
 * @notice A base contract for selling content via authorised sellers.
 */
abstract contract BaseSellableUpgradeable is Initializable, ISellable, SteerableAccessControlEnumerableUpgradeable {
    /**
     * @notice Authorised sellers.
     */
    bytes32 public constant AUTHORISED_SELLER_ROLE = keccak256("AUTHORISED_SELLER_ROLE");

    function __BaseSellable_init() internal onlyInitializing {
        __AccessControlEnumerable_init();
        __BaseSellable_init_unchained();
    }

    function __BaseSellable_init_unchained() internal onlyInitializing {
        _setRoleAdmin(AUTHORISED_SELLER_ROLE, DEFAULT_STEERING_ROLE);
    }

    /**
     * @notice Handles the sale of sellable content via an authorised seller.
     * @dev Delegates the implementation to `_handleSale`.
     */
    function handleSale(address to, uint64 num, bytes calldata data)
        external
        payable
        onlyRole(AUTHORISED_SELLER_ROLE)
    {
        _handleSale(to, num, data);
    }

    /**
     * @notice Handles the sale of sellable content.
     */
    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual;

    /**
     * @notice Revokes approval for all sellers.
     */
    function _revokeAllSellers() internal {
        uint256 num = getRoleMemberCount(AUTHORISED_SELLER_ROLE);
        for (uint256 i = 0; i < num; i++) {
            // Akin to a popFront
            address seller = getRoleMember(AUTHORISED_SELLER_ROLE, 0);
            _revokeRole(AUTHORISED_SELLER_ROLE, seller);
        }
    }
}
