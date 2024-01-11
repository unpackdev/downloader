// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./IERC165.sol";

interface SupervisorInterface is IERC165 {
    /***  Manage your collateral assets ***/

    function enableAsCollateral(address[] calldata mTokens) external;

    function disableAsCollateral(address mToken) external;

    /*** Policy Hooks ***/

    function beforeLend(
        address mToken,
        address lender,
        uint256 wrapBalance
    ) external;

    function beforeRedeem(
        address mToken,
        address redeemer,
        uint256 redeemTokens
    ) external;

    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external;

    function beforeBorrow(
        address mToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function beforeRepayBorrow(address mToken, address borrower) external;

    function beforeAutoLiquidationSeize(
        address mToken,
        address liquidator_,
        address borrower
    ) external;

    function beforeAutoLiquidationRepay(
        address liquidator,
        address borrower,
        address mToken,
        uint224 borrowIndex
    ) external;

    function beforeTransfer(
        address mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function beforeFlashLoan(
        address mToken,
        address receiver,
        uint256 amount,
        uint256 fee
    ) external;

    function isLiquidator(address liquidator) external;
}
