// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./console.sol";
import "./Math.sol";
import "./SafeMath.sol";

library LibSeedGenerator {
    using SafeMath for uint256;

    uint256 constant OFFSET_BLOCK = 32;

    function generateRandomSeed(uint256 nonce) public view returns (uint256 seed) {
        uint256 blockNum = offsetBlockNumber(OFFSET_BLOCK);
        uint256 randomInt = generateRandomInteger(blockNum, nonce);
        seed = uint256(uint256(keccak256(abi.encodePacked(
            uint256(blockhash(blockNum)),
            randomInt,
            msg.sender
        ))));
    }

    function generateRandomInteger(uint256 limit, uint256 nonce) public view returns (uint256 num) {
        num = uint256(uint256(keccak256(abi.encodePacked(
            uint256(blockhash(offsetBlockNumber(OFFSET_BLOCK))),
            nonce,
            msg.sender
        ))).mod(limit)).add(1);
    }

    function offsetBlockNumber(uint256 limit) public view returns (uint256 blockNum) {
        uint256 randomOffset = uint256(uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty
        ))).mod(limit)).add(1);
        blockNum = block.number.sub(Math.min(block.number, randomOffset));
        if (blockNum == 0) {
            blockNum = block.number;
        }
    }

    // function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    //     uint8 i = 0;
    //     while(i < 32 && _bytes32[i] != 0) {
    //         i++;
    //     }
    //     bytes memory bytesArray = new bytes(i);
    //     for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
    //         bytesArray[i] = _bytes32[i];
    //     }
    //     return string(bytesArray);
    // }
}