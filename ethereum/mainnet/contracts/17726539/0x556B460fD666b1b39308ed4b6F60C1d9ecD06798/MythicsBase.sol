// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import {ERC721RoyaltyUpgradeable} from
    "openzeppelin-contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import {ERC721PausableUpgradeable} from
    "openzeppelin-contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

import "./SteerableAccessControlEnumerableUpgradeable.sol";

/**
 * @notice Base contract for Mythics implementations.
 * @dev This contract is intended be inherited by all implementations and thus MUST NOT be changed.
 */
contract MythicsBase is
    Initializable,
    SteerableAccessControlEnumerableUpgradeable,
    ERC721Upgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721PausableUpgradeable,
    UUPSUpgradeable
{
    constructor() {
        _disableInitializers();
    }

    function __MythicsBase_init() internal onlyInitializing {
        __AccessControlEnumerable_init();
        __ERC721_init("Moonbirds: Mythics", "MYTHICS");
        __ERC721Royalty_init();
        __ERC721Pausable_init();
        __UUPSUpgradeable_init();
    }

    function __MythicsBase_init_unchained() internal onlyInitializing {}

    /**
     * @notice Only the admin is authorised to upgrade the implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev Needed for inheritance resolution.
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
    {
        ERC721PausableUpgradeable._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlEnumerableUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId)
            || ERC721RoyaltyUpgradeable.supportsInterface(interfaceId)
            || AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
        ERC721RoyaltyUpgradeable._burn(tokenId);
    }
}
