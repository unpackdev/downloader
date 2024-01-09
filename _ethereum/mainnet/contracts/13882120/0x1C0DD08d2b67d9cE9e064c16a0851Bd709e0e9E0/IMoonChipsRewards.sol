// contracts/IMBytes.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMoonChipsRewards {
    function updateBlockCount(uint256 _tokenId, uint256 _blockCount)
        external;
}