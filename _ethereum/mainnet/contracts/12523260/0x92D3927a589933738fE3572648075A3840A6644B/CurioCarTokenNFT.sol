/*
 * CurioCarTokenNFT
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - a minter role that allows for token minting (creation)
 *  - set token ID and URI in mint function by minter role
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter roles,
 * as well as the default admin role, which will let it grant minter role to other accounts.
 */
contract CurioCarTokenNFT is Context, AccessControlEnumerable, ERC721Enumerable, ERC721URIStorage {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` to the
     * account that deploys the contract.
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /**
     * @dev Creates a new token for `to` with `tokenId` and `_tokenURI`.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 tokenId, string memory _tokenURI) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "CurioCarTokenNFT: must have minter role to mint");

        _mint(to, tokenId);

        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Sets `_tokenURI` as new tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "CurioCarTokenNFT: must have minter role to mint");

        _setTokenURI(tokenId, _tokenURI);
    }


    // override parent functions

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
