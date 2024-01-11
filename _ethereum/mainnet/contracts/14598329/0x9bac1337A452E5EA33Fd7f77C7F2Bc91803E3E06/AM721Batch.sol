
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./AM721Enumerable.sol";
import "./IERC721Batch.sol";

abstract contract AM721Batch is AM721Enumerable, IERC721Batch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view override returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( _owners[ tokenIds[i] ] != account )
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
        uint count;
        uint quantity = balanceOf( account );
        uint[] memory wallet = new uint[]( quantity );
        for( uint i; i < _owners.length; ++i ){
            if( account == _owners[i] ){
                wallet[ count++ ] = i;
                if( count == quantity )
                    return wallet;
            }
        }

        return wallet;
  }
}