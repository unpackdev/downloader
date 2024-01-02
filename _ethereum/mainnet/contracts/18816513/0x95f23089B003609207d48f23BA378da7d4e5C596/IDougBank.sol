// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

uint8 constant LEADERBOARD_SIZE = 8;

interface IDougBank {
    function onTokenMerged(
        uint8 _type,
        uint8 _rank,
        uint256 tokenA,
        uint256 tokenB,
        uint256 merged
    ) external;
}
