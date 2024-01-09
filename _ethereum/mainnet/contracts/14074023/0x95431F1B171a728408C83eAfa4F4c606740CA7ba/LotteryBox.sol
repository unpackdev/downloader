// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721.sol";

contract LotteryBox {

  // take 3 blocks' hash values to make a random seed
  uint constant SEED_BLOCK_HASH_AMOUNT = 3;
  
  // blackhash can only retrieve the most recent 256 blocks' hash values
  uint constant MAX_BLOCK_HASH_DISTANCE = 256;


  /**
   * generate a simple random number using the parameter
   */
  function simpleRandom(uint seed) internal view returns(uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      block.timestamp,
      seed
    )));
  }

  /**
   * Using the hashes of `SEED_BLOCK_HASH_AMOUNT` previously generated blocks as random seed to generate a random number, based on height of the request block
   */
  function randomNumber(uint requestBlockNumber, uint seed) internal view returns (uint256) {
    bytes32[SEED_BLOCK_HASH_AMOUNT] memory blockhashs;
    for (uint i = 0; i < SEED_BLOCK_HASH_AMOUNT; i++) {
      blockhashs[i] = blockhash(requestBlockNumber+1+i);
    }
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhashs,
      seed
    )));
  }

  /**
   * request status 
   */
  function boxState(uint requestBlockNumber) internal view returns (uint) {
    if (requestBlockNumber == 0) {
      return 0; // not requested
    }
    if (openCountdown(requestBlockNumber) > 0) {
      return 1; // waiting for reveal
    }
    if (timeoutCountdown(requestBlockNumber) > 0) {
      return 2; // waiting to reveal the result
    }

    return 3; // timeout
  }

  /**
   * reveal countdown
   */
  function openCountdown(uint requestBlockNumber) internal view returns(uint) {
    return countdown(requestBlockNumber, SEED_BLOCK_HASH_AMOUNT+1);
  }

  /**
   * timeout countdown
   */
  function timeoutCountdown(uint requestBlockNumber) internal view returns(uint) {
    return countdown(requestBlockNumber, MAX_BLOCK_HASH_DISTANCE+1);
  }

  /**
   * calculate countdown
   */
  function countdown(uint requestBlockNumber, uint v) internal view returns(uint) {
    uint diff = block.number - requestBlockNumber;
    if (diff > v) {
      return 0;
    }
    return v - diff;
  }

  /**
   * convert big random number into less or equal to 100 random number
   */
  function percentNumber(uint random) internal pure returns(uint) {
    if (random > 0) {
      return (random % 100) + 1;
    }
    return 0;
  }

  /**
   * generate big random number through block height
   */
  function openBox(uint requestBlockNumber) internal view returns (uint) {
    
    require(openCountdown(requestBlockNumber) == 0, "Invalid block number");

    
    if (timeoutCountdown(requestBlockNumber) > 0) {
      
      return randomNumber(requestBlockNumber, 0);
    } else {
     
      return 0;
    }

  }


}