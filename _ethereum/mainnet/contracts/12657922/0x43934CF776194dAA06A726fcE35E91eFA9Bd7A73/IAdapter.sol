// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IAdapter {
    /*
     * @return The wrapped token price in underlying (18 decimal places).
     */
    function getWrappedTokenPriceInUnderlying() external view returns (uint256);

    function getTotalRedeemableUnderlyingTokens()
        external
        view
        returns (uint256);

    function getRedeemableUnderlyingTokensFor(uint256 amount)
        external
        view
        returns (uint256);

    function depositUnderlyingToken(uint256 amount) external returns (uint256);

    function redeemWrappedToken(uint256 maxAmount)
        external
        returns (uint256 actualAmount, uint256 quantity);

    event DepositUnderlyingToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 underlyingAssetAmount,
        uint256 wrappedTokenQuantity,
        address operator,
        uint256 timestamp
    );

    event RedeemWrappedToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 maxWrappedTokenAmount,
        uint256 actualWrappedTokenAmount,
        uint256 underlyingAssetQuantity,
        address operator,
        uint256 timestamp
    );
}
