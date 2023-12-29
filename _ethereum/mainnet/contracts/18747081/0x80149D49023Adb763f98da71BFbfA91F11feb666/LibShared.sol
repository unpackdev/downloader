// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "./Constants.sol";

library LibShared {

    uint256 internal constant MASK_GAME_ROUND = 0xFFFFFFFF;
    uint256 internal constant MASK_GAME_NUMBER = 0xFFFFFF;
    uint256 internal constant MASK_COUNT = 0xFFFF;
    uint256 internal constant MASK_ROUND = 0xFF;

    function liveIndex(uint32 n) internal pure returns (uint8) {
        return uint8((n + 1) & 1);
    }

    function safeIndex(uint32 n) internal pure returns (uint8) {
        return uint8(n & 1);
    }

    function getLiveIndex(uint256 data) internal pure returns (uint8) {
        return liveIndex(uint32((data >> DATA_OFFSET_ROUND_COUNT) & MASK_ROUND));
    }

    function getSafeIndex(uint256 data) internal pure returns (uint8) {
        return safeIndex(uint32((data >> DATA_OFFSET_ROUND_COUNT) & MASK_ROUND));
    }

    function getGameNumber(uint256 data) internal pure returns (uint32) {
        return uint32((data >> DATA_OFFSET_GAME_NUMBER) & MASK_GAME_NUMBER);
    }

    function getGameRound(uint256 data) internal pure returns (uint32) {
        return uint32((data >> DATA_OFFSET_GAME_ROUND) & MASK_GAME_ROUND);
    }

    function setGameRound(uint256 data, uint32 gameRound) internal pure returns (uint256) {
        return (data & ~(MASK_GAME_ROUND << DATA_OFFSET_GAME_ROUND)) | (uint256(gameRound) << DATA_OFFSET_GAME_ROUND);
    }

    function clearRound(uint256 data) internal pure returns (uint256) {
        return (data & ~(MASK_ROUND << DATA_OFFSET_ROUND_COUNT));
    }

    function getLiveCount(uint256 data) internal pure returns (uint16) {
        return uint16((data >> DATA_OFFSET_LIVE_COUNT) & MASK_COUNT);
    }

    function addLiveCount(uint256 data, uint16 count) internal pure returns (uint256) {
        unchecked {
            return data + (uint256(count) << DATA_OFFSET_LIVE_COUNT);
        }
    }

    function subLiveCount(uint256 data, uint16 count) internal pure returns (uint256) {
        unchecked {
            return data - (uint256(count) << DATA_OFFSET_LIVE_COUNT);
        }
    }

    function setLiveCount(uint256 data, uint16 count) internal pure returns (uint256) {
        return clearLiveCount(data) | (uint256(count) << DATA_OFFSET_LIVE_COUNT);
    }

    function clearLiveCount(uint256 data) internal pure returns (uint256) {
        return data & ~(MASK_COUNT << DATA_OFFSET_LIVE_COUNT);
    }

    function getSafeCount(uint256 data) internal pure returns (uint16) {
        return uint16((data >> DATA_OFFSET_SAFE_COUNT) & MASK_COUNT);
    }

    function addSafeCount(uint256 data, uint16 count) internal pure returns (uint256) {
        unchecked {
            return data + (uint256(count) << DATA_OFFSET_SAFE_COUNT);
        }
    }

    function subSafeCount(uint256 data, uint16 count) internal pure returns (uint256) {
        unchecked {
            return data - (uint256(count) << DATA_OFFSET_SAFE_COUNT);
        }
    }

    function setSafeCount(uint256 data, uint16 count) internal pure returns (uint256) {
        return clearSafeCount(data) | (uint256(count) << DATA_OFFSET_SAFE_COUNT);
    }

    function clearSafeCount(uint256 data) internal pure returns (uint256) {
        return data & ~(MASK_COUNT << DATA_OFFSET_SAFE_COUNT);
    }

    function getBurnCount(uint256 data) internal pure returns (uint16) {
        return uint16(data);
    }

    function addBurnCount(uint256 data, uint16 count) internal pure returns (uint256) {
        unchecked {
            return data + count;
        }
    }

    function setBurnCount(uint256 data, uint16 count) internal pure returns (uint256) {
        return clearBurnCount(data) | uint256(count);
    }

    function clearBurnCount(uint256 data) internal pure returns (uint256) {
        return data & ~MASK_COUNT;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
