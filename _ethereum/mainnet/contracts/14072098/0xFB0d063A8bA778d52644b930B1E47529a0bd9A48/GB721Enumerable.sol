// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-GB721 provides low-gas     *
 *       mints + transfers              *
 ****************************************/

import "./IERC721Enumerable.sol";
import "./GB721.sol";

abstract contract GB721Enumerable is GB721, IERC721Enumerable {
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, GB721) returns( bool isSupported ){
    return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  function tokenOfOwnerByIndex(address owner, uint index) external view override returns( uint tokenId ){
    uint count;
    for( uint i; i < owners.length; ++i ){
      if( owner == owners[i] ){
        if( count == index )
          return i;
        else
          ++count;
      }
    }

    revert( "GB721Enumerable: owner index out of bounds" );
  }

  function tokenByIndex(uint index) external view override returns( uint tokenId ){
    require(index < owners.length, "GB721Enumerable: query for nonexistent token");
    return index;
  }

  function totalSupply() public view override returns( uint totalSupply_ ){
    return owners.length ;
  }
}
