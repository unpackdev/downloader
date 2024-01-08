pragma solidity ^0.7.6;

import "./PriceOracle.sol";

abstract contract ControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata pTokens) external virtual returns (uint[] memory);
    function exitMarket(address pToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address pToken, address minter, uint mintAmount) external virtual returns (uint);
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external virtual returns (uint);

    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);

    function transferAllowed(address pToken, address src, address dst, uint transferTokens) external virtual returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);

    function getOracle() external view virtual returns (PriceOracle);
}
