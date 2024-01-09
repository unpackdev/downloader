
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   X-11                        *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721Enumerable is IERC165, IERC721Enumerable, ERC721 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint index) public view override returns (uint tokenId) {
        uint count;
        for( uint i; i < _owners.length; ++i ){
            if( owner == _owners[i] ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }

    function totalSupply() public view override( IERC721Enumerable, ERC721 ) returns (uint) {
        return _owners.length;
    }

    function tokenByIndex(uint index) external view override returns (uint) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }
}
