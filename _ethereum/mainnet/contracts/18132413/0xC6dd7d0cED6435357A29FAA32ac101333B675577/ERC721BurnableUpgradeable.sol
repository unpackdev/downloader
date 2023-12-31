// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721BurnableUpgradeable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */

abstract contract ERC721BurnableUpgradeable is IERC721BurnableUpgradeable, Initializable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {}

    function __ERC721Burnable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721BurnableUpgradeable__NotOwnerNorApproved();
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
