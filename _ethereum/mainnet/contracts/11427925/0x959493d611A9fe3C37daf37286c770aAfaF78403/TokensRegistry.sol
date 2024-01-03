//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./Address.sol";
import "./ITokensRegistry.sol";

contract TokensRegistry is ITokensRegistry {
    using Address for address;

    mapping(address => bool) allowedTokens;

    function addToken(address token) external override {
        require(token.isContract(), "TOKEN_MUST_BE_CONTRACT");

        allowedTokens[token] = true;

        emit TokenAdded(msg.sender, token);
    }

    function removeToken(address token) external override {
        allowedTokens[token] = false;

        emit TokenRemoved(msg.sender, token);
    }

    function hasToken(address token) external view override returns (bool) {
        return allowedTokens[token];
    }
}
