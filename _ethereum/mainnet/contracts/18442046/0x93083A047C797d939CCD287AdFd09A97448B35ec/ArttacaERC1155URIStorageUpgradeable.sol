// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc1155/ArttacaERC1155URIStorageUpgradeable.sol)

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC1155Upgradeable.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC1155URIStorage OpenZeppelin extension
 */
abstract contract ArttacaERC1155URIStorageUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155URIStorage_init() internal onlyInitializing {
        __ERC1155URIStorage_init_unchained();
    }

    function __ERC1155URIStorage_init_unchained() internal onlyInitializing {}

    // @dev mapping for token URIs
    mapping(uint => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the token-specific uri
     *
     * - if `_tokenURIs[tokenId]` is set, thein is returned
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint tokenId) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[50] private __gap;
}
