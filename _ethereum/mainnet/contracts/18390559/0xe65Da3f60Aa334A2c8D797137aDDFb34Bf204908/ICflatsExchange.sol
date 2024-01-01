// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title The interface for implementing the CflatsExchange smart contract 
/// with a full description of each function and their implementation 
/// is presented to your attention.

pragma solidity ^0.8.18;

interface ICflatsExchange 
{
    /// @dev Emitted when user exchanges assets for $CFLAT tokens
    /// `token0` is the address of token to exchange
    /// `token1` is the address of token to receive
    /// `amountsIn` is the amount of tokens to exchange
    /// `amounsOut` is the amount of tokens to receive
    event Exchanged(
        address indexed token0,
        address indexed token1,
        uint256 amountsIn,
        uint256 amounsOut
    );


    /// @dev Structure that stores the specified parameters for an exchanger for a specific asset
    ///
    /// `scopedTokenReserves` is amount of tokens that should be stored to update exchange price
    /// `minScopedTokenReserves` minimal scoped reserves. It will be setted once owner will claim token reserves
    /// `minExchangeRate` minimal exchange rate for token. It will be setted once owner will claim token reserves 
    /// `minSwapAmount` minimal allowed swap amount
    /// `currentExchangeRate` is the last setted exchange rate for token.
    /// It changes every time when `scopedTokenReserves` increases or decreases by 5% 
    struct CflatsExchangerInfo
    {
        uint256 scopedTokenReserves;
        uint256 minScopedTokenReserves;
        uint256 minSwapAmount;
        uint256 minExchangeRate;
        uint256 currentExchangeRate;
    }


    //************************* startregion: VARIABLES  *************************//

    /// @dev immutable variable for token that will be exchanged with other tokens
    /// @return address of token that will be exchanged for
    function ACCENT_TOKEN() external view returns(address);

    //************************* endregion: VARIABLES  *************************//




    //************************* startregion: CALLABLE FUNCTIONS  *************************//

    /// @dev Shows current info for exchanging this token to default token 
    /// @param exchangeToken token that should be exchanged with default token
    /// @return data for exchange token
    function getExchangeInfo(
        address exchangeToken
    ) external view returns (CflatsExchangerInfo memory);


    /// @dev Shows amounts that user will receive for amounts of asset he/she introduce
    /// @param exchangeToken token that should be exchanged with default token
    /// @param amountsIn amount of tokens that should be exchanged
    /// @return amounts of tokens that user will receive after swap
    function getAmountsOut(
        address exchangeToken,
        uint256 amountsIn
    ) external view returns (uint256);

    //************************* startregion: CALLABLE FUNCTIONS  *************************//




    //************************* startregion: SEND FUNCTIONS  *************************//

    /// @dev Sets the settings for the pair between the default token and
    /// the `exchangeToken` that will be active for exchange
    /// @param exchangeToken token that will be active for exchange
    /// @param exchangeRate initial for swap
    /// @param scopedTokenReserves scope for token reserves to update exchange price
    /// NOTE `scopedTokenReserves` will update exchange rate
    /// @param minSwapAmount minimal amount for user to swap
    ///
    /// @custom:requires token to be new, otherwise it will revert with
    /// error ExchangeTokenIsAlreadyAddedError()
    ///
    /// @custom:requires `exchangeRate` and `scopedTokenReserves` to be greather than zero
    /// error ExchangeTokenIsAlreadyAddedError()
    function addNewExchangeTokenPair(
        address exchangeToken, 
        uint256 exchangeRate,
        uint256 scopedTokenReserves,
        uint256 minSwapAmount
    ) external;


    /// @dev Removes info for exchange token pair
    function deleteExchangeTokenPair(address exchangeToken) external;


    /// @dev Function for exchanging `exchangeToken` in amount of `amountsIn`
    /// to ACCENT_TOKEN by exchange rate
    /// @param exchangeToken token that should be exchanged
    /// @param amountsIn amounts of tokens to exchange
    ///
    /// @custom:requires `exchangeToken` not to be zero address
    /// error ExchangeTokenIsAlreadyAddedError()
    ///
    /// @custom:requires `amountsIn` to be greather than or equal to `minSwapAmount`
    /// error SwapAmountIsTooSmallError()
    ///
    ///
    /// @custom:requires pair to be created otherwise it will revert with
    /// error ExchangeTokenPairIsNotCreatedError()
    function swapExactTokensForTokens(
        address exchangeToken,
        uint256 amountsIn
    ) external;


    /// @dev Function for exchanging `native token` in amount of `value`
    /// to ACCENT_TOKEN by exchange rate
    ///
    /// @custom:requires `value` to be greather than or equal to `minSwapAmount`
    /// error SwapAmountIsTooSmallError()
    ///
    /// @custom:requires pair to be created otherwise it will revert with
    /// error ExchangeTokenPairIsNotCreatedError()
    function swapExactEthForTokens() external payable;

    //************************* startregion: SEND FUNCTIONS  *************************//
}
