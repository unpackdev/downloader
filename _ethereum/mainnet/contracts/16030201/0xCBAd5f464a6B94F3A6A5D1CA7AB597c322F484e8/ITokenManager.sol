// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./AggregatorV3Interface.sol";

interface ITokenManager {
    struct TokenManagerInitParams {
        address[] acceptedTokens;
        address[] chainlinkAggregators;
    }

    function acceptedTokensList(uint256 index_)
        external
        returns (address token);

    function tokenInfo(address token_)
        external
        returns (uint8 accepted, AggregatorV3Interface chainlinkAggregator);

    function getAcceptedTokensCount()
        external
        view
        returns (uint256 tokenCount);

    function addTokens(
        address[] calldata tokens_,
        address[] calldata chainlinkAggregators_
    ) external;

    function removeTokens(address[] calldata tokens_) external;
}
