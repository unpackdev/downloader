// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "./LibShared.sol";
import "./Constants.sol";

library LibConfig {

    uint256 private constant CONFIG_OFFSET_MAX_TOKENS = 0;
    uint256 private constant CONFIG_OFFSET_MAX_WALLET = 16;
    uint256 private constant CONFIG_OFFSET_MAX_AMOUNT = 32;
    uint256 private constant CONFIG_OFFSET_CONTEST_ID = 48;
    uint256 private constant CONFIG_OFFSET_CONFIG_VER = 80;
    uint256 private constant CONFIG_OFFSET_TEAM_SPLIT = 88;
    uint256 private constant CONFIG_OFFSET_PRIZE_POOL = 96;
    uint256 private constant MASK_MAX_TOKENS = 0xFFFF;
    uint256 private constant MASK_MAX_WALLET = 0xFFFF;
    uint256 private constant MASK_MAX_AMOUNT = 0xFFFF;
    uint256 private constant MASK_PRIZE_POOL = 0xFFFF;
    uint256 private constant MASK_CONTEST_ID = 0xFFFF;
    uint256 private constant MASK_TEAM_SPLIT = 0xFF;
    uint256 private constant MASK_CONFIG_VER = 0xFF;
    uint256 private constant SCALAR_GWEI = 1e9;
    uint16 private constant CONTEST_ID_OFFSET_SERIES = 16;
    uint16 private constant MIN_TOKENS = 2;
    uint16 private constant MAX_TOKENS = 2**14;
    uint8 private constant MAX_TEAM_SPLIT = 50;
    uint8 private constant CONFIG_VERSION = 1;

    error ErrorMaxAmount();
    error ErrorMaxTokens();
    error ErrorMaxWallet();
    error ErrorTeamSplit();

    function initConfig(
        uint256 _tokenPrice,
        uint32 _contestId,
        uint16 _maxTokens,
        uint16 _maxWallet,
        uint16 _maxAmount,
        uint8 _teamSplit
    ) internal pure returns (uint256) {
        if ((_maxTokens < MIN_TOKENS) || (_maxTokens > MAX_TOKENS)) revert ErrorMaxTokens();
        if ((_maxWallet == 0) || (_maxWallet > _maxTokens)) revert ErrorMaxWallet();
        if ((_maxAmount == 0) || (_maxAmount > _maxWallet)) revert ErrorMaxAmount();
        if (_teamSplit > MAX_TEAM_SPLIT) revert ErrorTeamSplit();
        uint64 prizePool = uint64(((_tokenPrice * _maxTokens * (100 - _teamSplit)) / 100) / SCALAR_GWEI);
        if (_contestId <= type(uint16).max) {
            _contestId = (uint32(_maxTokens | uint16(prizePool / SCALAR_GWEI)) << CONTEST_ID_OFFSET_SERIES) | _contestId;
        }
        return
            (uint256(_maxTokens)     << CONFIG_OFFSET_MAX_TOKENS) |
            (uint256(_maxWallet)     << CONFIG_OFFSET_MAX_WALLET) |
            (uint256(_maxAmount)     << CONFIG_OFFSET_MAX_AMOUNT) |
            (uint256(_contestId)     << CONFIG_OFFSET_CONTEST_ID)  |
            (uint256(CONFIG_VERSION) << CONFIG_OFFSET_CONFIG_VER) |
            (uint256(_teamSplit)     << CONFIG_OFFSET_TEAM_SPLIT) |
            (uint256(prizePool)      << CONFIG_OFFSET_PRIZE_POOL);
    }

    function teamSplit(uint256 data) internal pure returns (uint8) {
        return uint8((data >> CONFIG_OFFSET_TEAM_SPLIT) & MASK_TEAM_SPLIT);
    }

    function maxAmount(uint256 data) internal pure returns (uint16) {
        return uint16((data >> CONFIG_OFFSET_MAX_AMOUNT) & MASK_MAX_AMOUNT);
    }

    function maxWallet(uint256 data) internal pure returns (uint16) {
        return uint16((data >> CONFIG_OFFSET_MAX_WALLET) & MASK_MAX_WALLET);
    }

    function maxTokens(uint256 data) internal pure returns (uint16) {
        return uint16((data >> CONFIG_OFFSET_MAX_TOKENS) & MASK_MAX_TOKENS);
    }
}
