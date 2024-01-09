pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

abstract contract Utils {
  uint public constant SUB_ID_RANGE    = 10 ** 11;
  uint public constant ARTIST_START_ID = 1 * SUB_ID_RANGE;
  uint public constant ART_START_ID    = 2 * SUB_ID_RANGE;

  function getRandom(uint max) internal view returns (uint) {
    return uint(
      keccak256(abi.encodePacked(msg.sender, block.difficulty, blockhash(block.number), block.timestamp))
    ) % max;
  }

  function getHybridId(uint _contentId, uint _styleId) public pure returns (uint) {
    return uint(keccak256(abi.encodePacked(_contentId, _styleId)));
  }

  function getArtistId(uint count) internal pure returns (uint256) {
    return ARTIST_START_ID + count;
  }

  function getArtId(uint count) internal pure returns (uint256) {
    return ART_START_ID + count;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}