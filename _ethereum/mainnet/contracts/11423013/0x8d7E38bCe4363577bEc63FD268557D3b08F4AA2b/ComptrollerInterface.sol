pragma solidity ^0.5.16;

contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata slTokens) external returns (uint[] memory);
    function exitMarket(address slToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address slToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address slToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address slToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address slToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address slToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address slToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address slToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address slToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address slTokenBorrowed,
        address slTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address slTokenBorrowed,
        address slTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address slTokenCollateral,
        address slTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address slTokenCollateral,
        address slTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address slToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address slToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address slTokenBorrowed,
        address slTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}
