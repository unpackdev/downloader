//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "./Base.sol";

// Interfaces
import "./ITokenValuator.sol";

contract OnlyTokenValuator is ITokenValuator, Base {
    mapping(address => bool) public asFungibleToken;

    mapping(address => uint256) public valuations;

    constructor(address settingsAddress) public Base(settingsAddress) {}

    function setAsFungibleToken(address[] calldata tokens, bool asFungible)
        external
        onlyConfigurator(msg.sender)
    {
        require(tokens.length > 0, "TOKENS_REQUIRED");
        for (uint256 indexAt = 0; indexAt < tokens.length; indexAt++) {
            asFungibleToken[tokens[indexAt]] = asFungible;
        }
        emit TokensAsFungibleSet(tokens, asFungible);
    }

    function setValuations(address[] calldata tokens, uint256 valuation)
        external
        onlyConfigurator(msg.sender)
    {
        require(tokens.length > 0, "TOKENS_REQUIRED");
        for (uint256 indexAt = 0; indexAt < tokens.length; indexAt++) {
            valuations[tokens[indexAt]] = valuation;
        }
        emit NewValuationsSet(tokens, valuation);
    }

    /* View Functions */

    function isConfigured(address token) external view override returns (bool) {
        return _isConfigured(token);
    }

    function requireIsConfigured(address token) external view override {
        require(_isConfigured(token), "TOKEN_ISNT_CONFIGURED");
    }

    function isFungibleToken(address token) external view returns (bool) {
        return asFungibleToken[token];
    }

    function hasValuation(
        address token,
        address,
        uint256,
        uint256
    ) external view override returns (bool) {
        return valuations[token] > 0;
    }

    function requireHasValuation(
        address token,
        address,
        uint256,
        uint256
    ) external view override {
        require(valuations[token] > 0, "TOKEN_HASNT_VALUATION");
    }

    function valuate(
        address token,
        address,
        uint256,
        uint256 amountOrId
    ) external view override returns (uint256) {
        return asFungibleToken[token] ? amountOrId : valuations[token];
    }

    /** Internal Functions */

    function _isConfigured(address token) internal view returns (bool) {
        return asFungibleToken[token] || valuations[token] > 0;
    }

    /* Events */

    event NewValuationsSet(address[] tokens, uint256 valuation);

    event TokensAsFungibleSet(address[] tokens, bool value);
}
