// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// The various sizes used in bytes.
uint256 constant ID_SIZE = 4;
uint256 constant ID_OFFSET_SIZE = 1;
uint256 constant WORD_SIZE = 32;

// The size that a delegate takes in the lookup table (Identifier + Offset).
uint256 constant TOTAL_ID_SIZE = 5; // ID_SIZE + ID_OFFSET_SIZE;

// The amount of bytes to go forward to get to the offset of the next delegate (aka. the end of the offset of the current delegate).
uint256 constant NEXT_DELEGATE_OFFSET = 9; // TOTAL_ID_SIZE + ID_SIZE;

// 1 word (32B) is reserved for the protocol .
uint256 constant RESERVED_SIZE = 32; // 1 * WORD_SIZE;
uint256 constant MIN_METADATA_LENGTH = 37; // RESERVED_SIZE + ID_SIZE + ID_OFFSET_SIZE;