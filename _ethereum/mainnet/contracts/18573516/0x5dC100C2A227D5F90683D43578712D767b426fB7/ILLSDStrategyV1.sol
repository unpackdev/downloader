// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreMulticallV1.sol";
import "./BaseSwap.sol";
import "./IBasePermissionedExecution.sol";

interface ILLSDStrategyV1 is ICoreMulticallV1, IBasePermissionedExecution {
    event Enter(
        uint256 collateral,
        uint256 collateralDelta,
        uint256 debt,
        uint256 debtDelta,
        address[] dryAssets,
        int256[] dryBalanceDeltas,
        uint256 ltv
    );

    event Exit(
        uint256 collateral,
        uint256 collateralDelta,
        uint256 debt,
        uint256 debtDelta,
        address[] dryAssets,
        int256[] dryBalanceDeltas,
        uint256 ltv
    );

    event SweepDust(uint256 collateral, uint256 collateralDelta, uint256 debt, uint256 debtDelta, uint256 ltv);

    struct EnterContext {
        uint256 flashloanAmount;
        SwapPayload swapPayload;
        uint256 maxLTV;
    }

    struct ExitContext {
        uint256 flashloanAmount;
        uint256 repayAmount;
        uint256 decollateralizeAmount;
        SwapPayload swapPayload;
        uint256 maxLTV;
    }

    enum FlashLoanContextType {
        ENTER,
        EXIT
    }

    function STAKED_TOKEN() external view returns (address);

    function STAKING_TOKEN() external view returns (address);

    /**
     * @notice  Enter or increase leverage using a flashloan.
     *     Steps:
     *     1.   Flashloan `flashloanAmount` of the staking asset (eg: WETH)
     *     2a.  On chains that support staking, stake the entire dry balance of the staking token (eg: WETH)
     *     2b.  All other chains, the `swapPayload` will swap `flashloanAmount` to the staked asset
     *     3.   Collateralize strategy balance of `dry` staked token (eg: wstETH)
     *     4.   Borrow `flashloanAmount`
     *     5.   Repay flashloan
     *     6.   Verify LTV is below inputted threshold
     * @dev Swapping is only initiated if `SwapPayload.amount` > 0.
     * @dev 2b: `SwapPayload.amount` determines the amount of staking asset to swap
     * @param flashloanAmount   Amount to flashloan
     * @param swapPayload       Swaps to staked asset when native staking is not possible.
     *                          Not used on chains that support native staking.
     * @param maxLTV            Verify LTV at the end of the operation
     */
    function enter(uint256 flashloanAmount, SwapPayload calldata swapPayload, uint256 maxLTV) external;

    /**
     * @notice  Enter or increase leverage using multicall looping.
     *     Steps:
     *     1.   Collateralize strategy balance of `dry` staked asset (eg: wstETH)
     *     2.   Borrow staking asset
     *     3a.  On chains that support staking, stake the entire dry balance of the staking token (eg: WETH)
     *     3b.  All other chains, the `swapPayload` will swap `flashloanAmount` to the staked asset
     *     4.   Verify LTV is below inputted threshold
     * @dev Swapping is only initiated if `SwapPayload.amount` > 0.
     *      This can occur to allow users to withdraw the staked asset.
     * @param borrowAmount      Amount to borrow
     * @param swapPayload       Swaps in to staked asset when native staking is not possible.
     * *                        Not used on chains that support native staking.
     * @param maxLTV            Verify LTV at the end of the operation
     */
    function enterMulticall(uint256 borrowAmount, SwapPayload calldata swapPayload, uint256 maxLTV) external;

    /**
     * @notice Exit or decrease leverage using a flashloan.
     *     Steps:
     *     1.   Flashloan `flashloanAmount` of the staking asset (eg: WETH)
     *     2.   Repay `repayAmount`
     *     3.   Decollateralize `flashloanAmount`
     *     4a.  On chains that support unstaking, unstake `flashloanAmount`
     *     4b.  All other chains, `swapPayload` will swap `decollateralizeAmount` out of the staked asset
     *     5.   Repay `flashloanAmount`
     *     6.   Verify LTV is below inputted threshold
     * @dev `flashloanAmount` less `repayAmount` is the amount of the staking asset to leave dry.
     * @dev Swapping is only initiated if `SwapPayload.amount` > 0.
     *      This can occur to allow users to withdraw the staked asset.
     * @param flashloanAmount   Amount to flashloan
     * @param repayAmount       Amount of `flashloanAmount` to repay
     * @param decollateralizeAmount       Amount of staked asset to remove as collateral
     * @param swapPayload       Swaps to staking asset when native unstaking is not possible
     *                          On chains that support unstaking, `SwapPayload.amount` is used to unstake
     * @param maxLTV            Verify LTV at the end of the operation
     */
    function exit(
        uint256 flashloanAmount,
        uint256 repayAmount,
        uint256 decollateralizeAmount,
        SwapPayload calldata swapPayload,
        uint256 maxLTV
    ) external;

    /**
     * @notice Exit or decrease leverage using multicall looping.
     *     Steps:
     *     1.   Decollateralize `decollateralizeAmount`
     *     2a.  On chains that support unstaking, unstake `decollateralizeAmount`
     *     2b.  All other chains, `swapPayload` will swap `decollateralizeAmount` out of the staked asset
     *     3.   If `repayDebt` is `true`, repay using the min(output of swap from step 2, outstanding debt)
     *          Minimum amount is used to allow users to withdraw the staked asset.
     *          If `repayDebt` is `false`, no repayment will be made.
     *     4.   Verify LTV is below inputted threshold
     * @dev Swapping is only initiated if `SwapPayload.amount` > 0.
     *      This can occur to allow users to withdraw the staked asset.
     * @dev `repayDebt` can be set to `true` to allow users to withdraw the staking asset.
     * @param decollateralizeAmount Amount of staked asset to remove as collateral
     * @param swapPayload       Swaps to staking asset when native unstaking is not possible
     *                          On chains that support unstaking, `SwapPayload.amount` is used to unstake
     * @param repayDebt         Flag to repay decollateralized asset
     * @param maxLTV            Verify LTV at the end of the operation
     */
    function exitMulticall(
        uint256 decollateralizeAmount,
        SwapPayload calldata swapPayload,
        bool repayDebt,
        uint256 maxLTV
    ) external;

    /**
     * @notice  Vault balances of supplyable assets are supplied;
     *          vault balances of repayable assets are repaid
     */
    function sweepDust() external;

    // view functions

    function getDebtAmount() external view returns (uint256);

    function getCollateralAmount() external view returns (uint256);

    /// @notice Returns the oracle price of the debt asset in terms of the collateral asset
    function getCollateralToDebtPrice() external view returns (uint256 price, uint256 precision);

    function getLTV() external view returns (uint256);
}
