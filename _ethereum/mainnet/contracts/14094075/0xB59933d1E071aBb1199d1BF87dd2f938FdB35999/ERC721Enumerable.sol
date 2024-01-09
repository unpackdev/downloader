// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;
import "./ERC721Optimized.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721Enumerable is ERC721Optimized, IERC721Enumerable {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Optimized) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        require(index < ERC721Optimized.balanceOf(owner), "ERC721Enumerable: owner ioob");
        uint count;
        for( uint i; i < _owners.length; ++i ){
            if( owner == _owners[i] ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }
        require(false, "ERC721Enumerable: owner ioob");
    }
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        require(0 < ERC721Optimized.balanceOf(owner), "ERC721Enumerable: owner ioob");
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global ioob");
        return index;
    }
}