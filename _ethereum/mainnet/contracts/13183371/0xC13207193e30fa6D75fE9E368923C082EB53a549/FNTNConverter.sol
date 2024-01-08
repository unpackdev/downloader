// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract FNTNConverter {
  /*
   * The tokenIds are not contiguous in the original contract
   * Given the id of a shard (the numner in the title, eg "FNTN // 62")
   * this outputs the actual tokenId in the original shared contract.
   */
  function shardIdToTokenId(uint shardId) public pure returns (uint) {
    // Check up front for a valid id. Saves gas on failure, but also on valid
    // shardIds we can save some gas by not needing SafeMath function calls
    require(shardId >= 1 && shardId <= 175, "Enter a shardId from 1 to 175");

    uint tokenId = 0;

    if (shardId == 1) {
      tokenId = 1230;
    } else if (shardId == 2) {
      tokenId = 1420;
    } else if (shardId > 2 && shardId < 8) {
      tokenId = 1229 + shardId;
    } else if (shardId > 7 && shardId < 37) {
      tokenId = 1230 + shardId;
    } else if (shardId > 36 && shardId < 63) {
      tokenId = 1231 + shardId;
    } else if (shardId > 62 && shardId < 76) {
      tokenId = 1242 + shardId;
    } else if (shardId > 75 && shardId < 109) {
      tokenId = 1244 + shardId;
    } else if (shardId > 108 && shardId < 165) {
      tokenId = 1245 + shardId;
    } else if (shardId > 164 && shardId < 168) {
      tokenId = 1129 + shardId;
    } else if (shardId == 168) {
      tokenId = 1300;
    } else if (shardId == 169) {
      tokenId = 1298;
    } else if (shardId == 170) {
      tokenId = 1299;
    } else if (shardId > 170 && shardId < 175) {
      tokenId = 1130 + shardId;
    } else if (shardId == 175) {
      tokenId = 1229;
    }

    return tokenId;
  }
  
  function tokenIdToShardId(uint tokenId) public pure returns (uint) {
    // Check up front for a valid id. Saves gas on failure, but also on valid
    // shardIds we can save some gas by not needing SafeMath function calls
    require(tokenId >= 1229 && tokenId <= 1420, "Enter a tokenId from 1229 to 1420");
    uint shardId = 0;

    if (tokenId == 1229) {
      shardId = 175;
    } else if (tokenId == 1230) {
      shardId = 1;
    } else if(tokenId > 1231 && tokenId < 1237) {
      shardId = tokenId - 1229;
    } else if(tokenId > 1237 && tokenId < 1267) {
      shardId = tokenId - 1230;
    } else if(tokenId > 1267 && tokenId < 1294) {
      shardId = tokenId - 1231;
    } else if(tokenId > 1293 && tokenId < 1297) {
      shardId = tokenId - 1129;
    } else if(tokenId == 1298) {
      shardId = 169;
    } else if(tokenId == 1299) {
       shardId = 170;
    } else if(tokenId == 1300) {
       shardId = 168;
    } else if(tokenId > 1300 && tokenId < 1305) {
      shardId = tokenId - 1130;
    } else if(tokenId > 1304 && tokenId < 1318) {
      shardId = tokenId - 1242;
    } else if(tokenId > 1319 && tokenId < 1353) {
      shardId = tokenId - 1244;
    } else if(tokenId > 1353 && tokenId < 1410) {
      shardId = tokenId - 1245;
    } else if(tokenId == 1420) {
      shardId = 2;
    }

    return shardId;
  }
}
