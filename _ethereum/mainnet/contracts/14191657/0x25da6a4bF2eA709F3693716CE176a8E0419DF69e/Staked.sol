
// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

abstract contract Staked {
  modifier notStaked( uint tokenId ) {
    require( !_isStaked( tokenId ), "Token is locked during staking" );
    _;
  }

  function _isStaked( uint tokenId ) internal view virtual returns (bool isStaked_);
}
