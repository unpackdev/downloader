// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20Short.sol";

abstract contract TokensPreset {
    using SafeMath for uint256;

    uint256 public tokensTotal;

    struct TokenInfo {
        bool enabled;
        address token;
        string description;
        uint256 received;
        uint256 sent;
    }
    mapping(address => TokenInfo) public tokenInfo;
    mapping(uint256 => address) public tokenById;

    function isTokenEnabled(address token) public view returns (bool) {
        return tokenInfo[token].enabled;
    }

    function tokensUnaccounted(address token) public view returns (uint256) {
        uint256 balance = IERC20Short(token).balanceOf(address(this));
        uint256 received = tokenInfo[token].received;
        uint256 sent = tokenInfo[token].sent;
        return balance.sub(received.sub(sent));
    }

    function tokenBalance(address token) public view returns (uint256) {
        return IERC20Short(token).balanceOf(address(this));
    }

    function _addToken(address token, string memory description) internal {
        tokenInfo[token].enabled = false;
        tokenInfo[token].token = token;
        tokenInfo[token].description = description;
        tokenById[tokensTotal] = token;
        tokensTotal = tokensTotal.add(1);
    }

    function _setTokenStatus(address token, bool status) internal {
        tokenInfo[token].enabled = status;
    }
}
