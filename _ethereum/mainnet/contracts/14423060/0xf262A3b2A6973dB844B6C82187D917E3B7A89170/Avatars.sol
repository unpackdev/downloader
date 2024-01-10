// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Avatars is Context, ERC721URIStorage, ERC721Enumerable, Ownable {
    /**
     * Initializes the smart contract.
     */
    constructor() ERC721("Autentica Avatars", "AUT") {}

    /**
     * @dev Mints a new token.
     *
     * @param uri Token URI.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must be the contract owner.
     */
    function mint(string memory uri) external onlyOwner returns (uint256) {
        address creator = _msgSender();

        // Mint
        uint256 tokenId = totalSupply() + 1;
        _safeMint(creator, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    /**
     * Returns the Uniform Resource Identifier (URI) for a token.
     *
     * @param tokenId Token ID for which to return the URI.
     *
     * Requirements:
     *
     * - Token must exist.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `uri` as the tokenURI of `tokenId`. Useful when we want to migrate a token to IPFS.
     *
     * @param tokenId Token ID for which to set the URI.
     * @param uri The URI to set to the `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - The caller must own `tokenId`.
     */
    function setTokenURI(uint256 tokenId, string memory uri) external {
        address owner = ERC721.ownerOf(tokenId);
        require(
            owner == _msgSender(),
            "Avatars: caller is not owner"
        );

        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * Hook that is called before any token transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
