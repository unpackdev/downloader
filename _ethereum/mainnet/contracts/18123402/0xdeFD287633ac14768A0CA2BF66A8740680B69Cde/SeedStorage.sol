// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  SeedStorage
 * @author slvrfn
 * @notice Library responsible for loading the associated "layout" from storage, and setting/retrieving
 *         the internal fields.
 */
library SeedStorage {
    using SeedStorage for SeedStorage.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("genesis.libraries.storage.SeedStorage");

    struct Layout {
        uint256 seed;
        uint216 nonce;
        uint40 expirationTime;
    }

    /**
     * @notice Obtains the SeedStorage layout from storage.
     * @dev    layout is stored at the chosen STORAGE_SLOT.
     */
    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev    Obtains the current seed
     */
    function _seed(Layout storage s) internal view returns (uint256) {
        return s.seed;
    }

    /**
     * @dev    manually updates the the seed
     * @param  seed - the new seed value.
     */
    function _setSeed(Layout storage s, uint256 seed) internal {
        s.seed = seed;
    }

    /**
     * @dev Returns the current nonce
     */
    function _nonce(Layout storage s) internal view returns (uint216) {
        return s.nonce;
    }

    /**
     * @dev Increments the current nonce value and returns it.
     */
    function _incNonce(Layout storage s) internal returns (uint216) {
        uint216 newNonce;
        unchecked {
            newNonce = ++s.nonce;
        }
        return newNonce;
    }

    /**
     * @dev Returns the current seed countdown expiration.
     */
    function _expirationTime(Layout storage s) internal view returns (uint40) {
        return s.expirationTime;
    }

    /**
     * @dev Updates the current seed countdown expiration.
     */
    function _setExpirationTime(Layout storage s, uint40 newTime) internal {
        s.expirationTime = newTime;
    }
}
