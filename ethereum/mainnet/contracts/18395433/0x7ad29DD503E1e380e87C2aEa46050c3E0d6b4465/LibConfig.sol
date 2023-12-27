// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "./LibShared.sol";
import "./Constants.sol";

library LibConfig {

    uint256 private constant CONFIG_OFFSET_MAX_TOKENS = 0;
    uint256 private constant CONFIG_OFFSET_MAX_WALLET = 16;
    uint256 private constant CONFIG_OFFSET_MAX_TX = 32;
    uint256 private constant CONFIG_OFFSET_FREE = 48;
    uint256 private constant CONFIG_OFFSET_TEAM_SPLIT = 88;
    uint256 private constant CONFIG_OFFSET_TEAM_ADDRESS = 96;
    uint256 private constant MASK_MAX_TX = 0xFFFF;
    uint256 private constant MASK_MAX_WALLET = 0xFFFF;
    uint256 private constant MASK_MAX_TOKENS = 0xFFFF;
    uint256 private constant MASK_TEAM_SPLIT = 0xFF;

    struct Config {
        uint256 tokenPrice;
        uint256 data;
        address drawAddress;
    }

    error ErrorMaxTokens();
    error ErrorTokenPrice();
    error ErrorMaxWallet();
    error ErrorMaxTx();
    error ErrorTeamAddress();
    error ErrorDrawAddress();
    error ErrorTeamSplit();

    function initConfig(Config storage self,
        uint256 _tokenPrice,
        uint16 _maxTokens,
        uint16 _maxWallet,
        uint16 _maxTx,
        uint8 _teamSplit,
        address _teamAddress,
        address _drawAddress
    ) internal {
        if (_tokenPrice == 0) revert ErrorTokenPrice();
        if ((_maxTokens < MIN_TOKENS) || (_maxTokens > MAX_TOKENS)) revert ErrorMaxTokens();
        if ((_maxWallet == 0) || (_maxWallet > _maxTokens)) revert ErrorMaxWallet();
        if ((_maxTx == 0) || (_maxTx > _maxWallet)) revert ErrorMaxTx();
        if (_teamSplit > MAX_TEAM_SPLIT) revert ErrorTeamSplit();
        if (_teamAddress == address(0)) revert ErrorTeamAddress();
        if (_drawAddress == address(0)) revert ErrorDrawAddress();
        self.tokenPrice = _tokenPrice;
        self.data |=
            (uint256(_maxTokens)            << CONFIG_OFFSET_MAX_TOKENS) |
            (uint256(_maxWallet)            << CONFIG_OFFSET_MAX_WALLET) |
            (uint256(_maxTx)                << CONFIG_OFFSET_MAX_TX)     |
            (uint256(_teamSplit)            << CONFIG_OFFSET_TEAM_SPLIT) |
            (uint256(uint160(_teamAddress)) << CONFIG_OFFSET_TEAM_ADDRESS);
        self.drawAddress = _drawAddress;
    }

    function setAddresses(Config storage self,
        address _teamAddress,
        address _drawAddress
    ) internal {
        if (_teamAddress == address(0)) revert ErrorTeamAddress();
        if (_drawAddress == address(0)) revert ErrorDrawAddress();
        self.data |= uint256(uint160(_teamAddress)) << CONFIG_OFFSET_TEAM_ADDRESS;
        self.drawAddress = _drawAddress;
    }

    function teamAddress(Config storage self
    ) internal view returns (address) {
        return teamAddress(self.data);
    }

    function teamSplit(Config storage self
    ) internal view returns (uint8) {
        return teamSplit(self.data);
    }

    function maxTx(Config storage self
    ) internal view returns (uint16) {
        return maxTx(self.data);
    }

    function maxWallet(Config storage self
    ) internal view returns (uint16) {
        return maxWallet(self.data);
    }

    function maxTokens(Config storage self
    ) internal view returns (uint16) {
        return maxTokens(self.data);
    }

    function teamAddress(uint256 data) internal pure returns (address) {
        return address(uint160(data >> CONFIG_OFFSET_TEAM_ADDRESS));
    }

    function teamSplit(uint256 data) internal pure returns (uint8) {
        return uint8((data >> CONFIG_OFFSET_TEAM_SPLIT) & MASK_TEAM_SPLIT);
    }

    function maxTx(uint256 data) internal pure returns (uint16) {
        return uint16((data >> CONFIG_OFFSET_MAX_TX) & MASK_MAX_TX);
    }

    function maxWallet(uint256 data) internal pure returns (uint16) {
        return uint16((data >> CONFIG_OFFSET_MAX_WALLET) & MASK_MAX_WALLET);
    }

    function maxTokens(uint256 data) internal pure returns (uint16) {
        return uint16((data >> CONFIG_OFFSET_MAX_TOKENS) & MASK_MAX_TOKENS);
    }
}
