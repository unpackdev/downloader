// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

import "./MultiOwnable.sol";
import "./ERC721Royalties.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract ERC721Artist is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalties, MultiOwnable {
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @dev Mint a token.
     *
     * @param to      Address to mint to.
     * @param tokenId Desired tokenId.
     * @param uri     Metadata uri for the token.
     */
    function mint(address to, uint256 tokenId, string memory uri) public onlyOwner {

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }
    }

    /**
     * @dev Burn a token. Allows re-minting same tokenId after burn.
     *
     * @param tokenId The tokenId to burn.
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev see {ERC721-_burn}
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev see {ERC721URIStorage-tokenURI}
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Updates the metadata uri for a token.
     *
     * @param tokenId The tokenId to update.
     * @param uri     The new metadata uri.
     */
    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }
    }

    /**
     * @dev Sets the contract roylaties for all tokens.
     *
     * @param recipient The royalty recipient's address.
     * @param basisPoints The royalty bps. 100% is 10,000, 10% is 1,000, 0% is 0.
     */
    function setRoyalties(address recipient, uint256 basisPoints) public override onlyOwner {
        _setRoyalties(recipient, basisPoints);
    }

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721Royalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev see {ERC721Enumerable-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
