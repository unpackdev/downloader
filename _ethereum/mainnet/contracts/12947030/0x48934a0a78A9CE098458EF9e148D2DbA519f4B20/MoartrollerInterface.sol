// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./MToken.sol";
import "./ExponentialNoError.sol";

interface MoartrollerInterface {

    /**
 * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
 *  Note that `mTokenBalance` is the number of mTokens the account owns in the market,
 *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
 */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint mTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        ExponentialNoError.Exp collateralFactor;
        ExponentialNoError.Exp exchangeRate;
        ExponentialNoError.Exp oraclePrice;
        ExponentialNoError.Exp tokensToDenom;
    }

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata mTokens) external returns (uint[] memory);
    function exitMarket(address mToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address mToken, address minter, uint mintAmount) external returns (uint);

    function redeemAllowed(address mToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address mToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address mToken, address borrower, uint borrowAmount) external returns (uint);

    function repayBorrowAllowed(
        address mToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);

    function liquidateBorrowAllowed(
        address mTokenBorrowed,
        address mTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);

    function seizeAllowed(
        address mTokenCollateral,
        address mTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);

    function transferAllowed(address mToken, address src, address dst, uint transferTokens) external returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeUserTokens(
        address mTokenBorrowed,
        address mTokenCollateral,
        uint repayAmount,
        address account) external view returns (uint, uint);

    function getUserLockedAmount(MToken asset, address account) external view returns(uint);
}
