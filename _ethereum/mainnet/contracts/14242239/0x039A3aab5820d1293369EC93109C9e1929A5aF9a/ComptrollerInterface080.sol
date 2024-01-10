// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Keep in sync with ComptrollerInterface.sol.
abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint[] memory);
    function exitMarket(address cToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external virtual returns (uint);

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external virtual returns (uint);

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external virtual returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);

    function liquidateCalculateSeizeNfts(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);
}
