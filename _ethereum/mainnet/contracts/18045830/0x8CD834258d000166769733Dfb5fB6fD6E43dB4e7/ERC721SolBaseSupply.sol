// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// OZ Libraries
import "./Context.sol";

// NFTC Open Source Contracts (https://github.com/NFTCulture/nftc-contracts/tree/main)
import "./ERC721.sol";

/**
 * @title ERC721SolBaseSupply
 * @author @NiftyMike | @NFTCulture
 *
 * @dev ERC721 SolBase extension to enable tracking of supply and number minted.
 *
 * NOTE: Not a full ERC721Enumerable implementation.
 */
abstract contract ERC721SolBaseSupply is ERC721 {
    uint64 private mintedTokenCounter;
    uint64 private burnedTokenCounter;

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply();
    }

    function _totalSupply() internal view virtual returns (uint256) {
        return mintedTokenCounter - burnedTokenCounter;
    }

    function totalMinted() public view virtual returns (uint256) {
        return _totalMinted();
    }

    function _totalMinted() internal view virtual returns (uint256) {
        return mintedTokenCounter;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        super.transferFrom(from, to, tokenId);

        if (to == address(0)) {
            burnedTokenCounter++;
        }
    }

    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);

        mintedTokenCounter++;
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);

        burnedTokenCounter++;
    }

    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }
}
