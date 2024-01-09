
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721Batch.sol";

abstract contract ERC721Batch is ERC721Enumerable, IERC721Batch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view override returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( tokens[ tokenIds[i] ].owner != account )
        return false;
    }

    return true;
  }

  function transferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external override{
    for(uint i; i < tokenIds.length; ++i ){
      safeTransferFrom( from, to, tokenIds[i], data );
    }
  }

  function walletOfOwner( address account ) external view override returns( uint[] memory ){
    return _balances[ account ];
  }
}