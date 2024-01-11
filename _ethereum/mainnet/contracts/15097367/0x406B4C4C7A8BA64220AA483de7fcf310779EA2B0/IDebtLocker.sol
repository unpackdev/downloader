// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./IMapleProxied.sol";

/// @title DebtLocker interacts with Loans on behalf of PoolV1.
interface IDebtLocker is IMapleProxied {

    /**************/
    /*** Events ***/
    /**************/

    /**
     * @dev   Emitted when `setAllowedSlippage` is called.
     * @param newSlippage_ New value for `allowedSlippage`.
     */
    event AllowedSlippageSet(uint256 newSlippage_);

    /**
     * @dev   Emitted when `setAuctioneer` is called.
     * @param newAuctioneer_ New value for `auctioneer` in Liquidator.
     */
    event AuctioneerSet(address newAuctioneer_);

    /**
     * @dev   Emitted when `fundsToCapture` is set.
     * @param amount_ The amount of funds that will be captured next claim.
     */
    event FundsToCaptureSet(uint256 amount_);

    /**
     * @dev Emitted when `stopLiquidation` is called.
     */
    event LiquidationStopped();

    /**
     * @dev   Emitted when `setMinRatio` is called.
     * @param newMinRatio_ New value for `minRatio`.
     */
    event MinRatioSet(uint256 newMinRatio_);

    /*****************/
    /*** Functions ***/
    /*****************/

    /**
     * @dev   Accept the new loan terms and trigger a refinance.
     * @param refinancer_ The address of the refinancer contract.
     * @param deadline_   The deadline of the new terms proposal.
     * @param calls_      The array of encoded data that are to be executed as delegatecalls by the refinancer.
     * @param amount_     The amount of `fundsAsset` that is to be sent to the Loan as part of the transaction.
     */
    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_, uint256 amount_) external;

    /**
     *  @dev    Claims funds to send to Pool. Handles funds from payments and liquidations.
     *          Only the Pool can call this function.
     *  @return details_
     *              [0] => Total Claimed.
     *              [1] => Interest Claimed.
     *              [2] => Principal Claimed.
     *              [3] => Pool Delegate Fees Claimed.
     *              [4] => Excess Returned Claimed.
     *              [5] => Amount Recovered (from Liquidation).
     *              [6] => Default Suffered.
     */
    function claim() external returns (uint256[7] memory details_);

    /**
     * @dev   Allows the poolDelegate to pull some funds from liquidator contract.
     * @param liquidator_  The liquidator to which pull funds from.
     * @param token_       The token address of the funds.
     * @param destination_ The destination address of captured funds.
     * @param amount_      The amount to pull.
     */
    function pullFundsFromLiquidator(address liquidator_, address token_, address destination_, uint256 amount_) external;

    /**
     * @dev Returns the address of the Pool Delegate that has control of the DebtLocker.
     */
    function poolDelegate() external view returns (address poolDelegate_);

    /**
     * @dev Repossesses funds and collateral from a loan and transfers them to the Liquidator.
     */
    function triggerDefault() external;

    /**
     * @dev   Reject the new loan terms.
     * @param refinancer_ The address of the refinancer contract.
     * @param deadline_   The deadline of the new terms proposal.
     * @param calls_      The array of encoded data that are to be executed as delegatecalls by the refinancer.
     */
    function rejectNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_) external;

    /**
     * @dev   Sets the allowed slippage for auctioneer (used to determine expected amount to be returned in flash loan).
     * @param allowedSlippage_ Basis points representation of allowed percent slippage from market price.
     */
    function setAllowedSlippage(uint256 allowedSlippage_) external;

    /**
     * @dev   Sets the auctioneer contract for the liquidator.
     * @param auctioneer_ Address of auctioneer contract.
     */
    function setAuctioneer(address auctioneer_) external;

    /**
     * @dev   Sets the minimum "price" for auctioneer (used to determine expected amount to be returned in flash loan).
     * @param minRatio_ Price in fundsAsset precision (e.g., 10 * 10 ** 6 for $10 price for USDC).
     */
    function setMinRatio(uint256 minRatio_) external;

    /**
     * @dev    Returns the expected amount to be returned to the liquidator during a flash borrower liquidation.
     * @param  swapAmount_   Amount of collateralAsset being swapped.
     * @return returnAmount_ Amount of fundsAsset that must be returned in the same transaction.
     */
    function getExpectedAmount(uint256 swapAmount_) external view returns (uint256 returnAmount_);

    /**
     * @dev   Returns the expected amount to be returned to the liquidator during a flash borrower liquidation.
     * @param amount_ The amount of funds that should be captured next claim.
     */
    function setFundsToCapture(uint256 amount_) external;

    /**
     * @dev Called by the PoolDelegate in case of a DoS, where a user transfers small amounts of collateralAsset into the Liquidator
     *      to make `_isLiquidationActive` remain true.
     *      CALLING THIS MAY RESULT IN RECOGNIZED LOSSES IN POOL ACCOUNTING. CONSULT MAPLE TEAM FOR GUIDANCE.
     */
    function stopLiquidation() external;

    /*************/
    /*** State ***/
    /*************/

    /**
     * @dev The Loan contract this locker is holding tokens for.
     */
    function loan() external view returns (address loan_);

    /**
     * @dev The address of the liquidator.
     */
    function liquidator() external view returns (address liquidator_);

    /**
     * @dev The owner of this Locker (the Pool).
     */
    function pool() external view returns (address pool_);

    /**
     * @dev The maximum slippage allowed during liquidations.
     */
    function allowedSlippage() external view returns (uint256 allowedSlippage_);

    /**
     * @dev The amount in funds asset recovered during liquidations.
     */
    function amountRecovered() external view returns (uint256 amountRecovered_);

    /**
     * @dev The minimum exchange ration between funds asset and collateral asset.
     */
    function minRatio() external view returns (uint256 minRatio_);

    /**
     * @dev Returns the principal that was present at the time of last claim.
     */
    function principalRemainingAtLastClaim() external view returns (uint256 principalRemainingAtLastClaim_);

    /**
     * @dev Returns if the funds have been repossessed.
     */
    function repossessed() external view returns (bool repossessed_);

    /**
     * @dev Returns the amount of funds that will be captured next claim.
     */
    function fundsToCapture() external view returns (uint256 fundsToCapture_);

}
