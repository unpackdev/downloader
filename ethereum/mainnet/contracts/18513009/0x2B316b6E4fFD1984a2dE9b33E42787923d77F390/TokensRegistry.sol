// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IERC20.sol";
import "./Ownable.sol";

import "./AggregatorV3Interface.sol";

import "./Common.sol";

/// @title TokensRegistry contract
/// @notice Implements the pricefeed of the tokens

abstract contract TokensRegistry is Ownable {
    /// @notice The USDT normalization factor between DOP and USDT
    uint256 internal constant NORMALIZATION_FACTOR_DOP_USDT = 1e30;

    /// @notice Gives us onchain price oracle address of the token
    mapping(IERC20 => PriceFeedData) public tokenData;

    /// @dev Emitted when address of Chainlink priceFeed contract is added for the token
    event TokenDataAdded(IERC20 token, AggregatorV3Interface priceFeed);

    /// @member priceFeed The Chainlink priceFeed address
    /// @member normalizationFactorForToken The normalization factor to achieve return value of 18 decimals ,while calculating dop token purchases and always with different token decimals
    /// @member normalizationFactorForNFT The normalization factor is the value which helps us to convert decimals of USDT to investment token decimals and always with different token decimals
    struct PriceFeedData {
        AggregatorV3Interface priceFeed;
        uint8 normalizationFactorForToken;
        uint8 normalizationFactorForNFT;
    }

    /// @notice Of Chainlink price feed contracts
    /// @param tokens The addresses of the tokens
    /// @param priceFeedData Contains the priceFeed of the tokens and the normalization factor
    function setTokenPriceFeed(
        IERC20[] calldata tokens,
        PriceFeedData[] calldata priceFeedData
    ) external onlyOwner {
        if (tokens.length == 0) {
            revert ZeroLengthArray();
        }
        if (tokens.length != priceFeedData.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i = 0; i < tokens.length; ++i) {
            PriceFeedData memory data = priceFeedData[i];
            IERC20 token = tokens[i];
            PriceFeedData memory currentPriceFeedData = tokenData[token];
            if (
                address(token) == address(0) ||
                address(data.priceFeed) == address(0)
            ) {
                revert ZeroAddress();
            }
            if (
                currentPriceFeedData.priceFeed == data.priceFeed &&
                currentPriceFeedData.normalizationFactorForToken ==
                data.normalizationFactorForToken &&
                currentPriceFeedData.normalizationFactorForNFT ==
                data.normalizationFactorForNFT
            ) {
                revert IdenticalValue();
            }
            emit TokenDataAdded({token: token, priceFeed: data.priceFeed});
            tokenData[token] = data;
        }
    }
}
