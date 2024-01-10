// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "./IMarketController.sol";

/**
 * @title MarketClientLib
 *
 * Maintains the implementation address and the access and market controller addresses.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
library MarketClientLib {

    struct ProxyStorage {

        // The Seen.Haus AccessController address
        IAccessControlUpgradeable accessController;

        // The Seen.Haus MarketController address
        IMarketController marketController;

        // The implementation address
        address implementation;
    }

    /**
     * @dev Storage slot with the address of the Seen.Haus AccessController
     * This is obviously not a standard EIP-1967 slot.
     */
    bytes32 internal constant PROXY_SLOT = keccak256('Seen.Haus.MarketClientProxy');

    /**
     * @notice Get the Proxy storage slot
     *
     * @return ps - Proxy storage slot cast to ProxyStorage
     */
    function proxyStorage() internal pure returns (ProxyStorage storage ps) {
        bytes32 position = PROXY_SLOT;
        assembly {
            ps.slot := position
        }
    }

    /**
     * @dev Checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    function hasRole(bytes32 role) internal view returns (bool) {
        ProxyStorage storage ps = proxyStorage();
        return ps.accessController.hasRole(role, msg.sender);
    }

}