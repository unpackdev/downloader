// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IERC20 }                from "../modules/erc20/src/interfaces/IERC20.sol";
import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import "./MapleProxiedInternals.sol";

import "./Interfaces.sol";
import { IMapleLoanFactory }              from "./interfaces/IMapleLoanFactory.sol";

/// @title MapleLoanInternals defines the storage layout and internal logic of MapleLoan.
abstract contract MapleLoanInternals is MapleProxiedInternals {

    uint256 private constant SCALED_ONE = uint256(10 ** 18);

    // Roles
    address internal _borrower;         // The address of the borrower.
    address internal _lender;           // The address of the lender.
    address internal _pendingBorrower;  // The address of the pendingBorrower, the only address that can accept the borrower role.
    address internal _pendingLender;    // The address of the pendingLender, the only address that can accept the lender role.

    // Assets
    address internal _collateralAsset;  // The address of the asset used as collateral.
    address internal _fundsAsset;       // The address of the asset used as funds.

    // Loan Term Parameters
    uint256 internal _gracePeriod;      // The number of seconds a payment can be late.
    uint256 internal _paymentInterval;  // The number of seconds between payments.

    // Rates
    uint256 internal _interestRate;         // The annualized interest rate of the loan.
    uint256 internal _earlyFeeRate;         // The fee rate for prematurely closing loans.
    uint256 internal _lateFeeRate;          // The fee rate for late payments.
    uint256 internal _lateInterestPremium;  // The amount to increase the interest rate by for late payments.

    // Requested Amounts
    uint256 internal _collateralRequired;  // The collateral the borrower is expected to put up to draw down all _principalRequested.
    uint256 internal _principalRequested;  // The funds the borrowers wants to borrow.
    uint256 internal _endingPrincipal;     // The principal to remain at end of loan.

    // State
    uint256 internal _drawableFunds;       // The amount of funds that can be drawn down.
    uint256 internal _claimableFunds;      // The amount of funds that the lender can claim (principal repayments, interest, etc).
    uint256 internal _collateral;          // The amount of collateral, in collateral asset, that is currently posted.
    uint256 internal _nextPaymentDueDate;  // The timestamp of due date of next payment.
    uint256 internal _paymentsRemaining;   // The number of payments remaining.
    uint256 internal _principal;           // The amount of principal yet to be paid down.

    // Refinance
    bytes32 internal _refinanceCommitment;

    /**********************************/
    /*** Internal General Functions ***/
    /**********************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        _gracePeriod     = uint256(0);
        _paymentInterval = uint256(0);

        _interestRate        = uint256(0);
        _earlyFeeRate        = uint256(0);
        _lateFeeRate         = uint256(0);
        _lateInterestPremium = uint256(0);

        _endingPrincipal = uint256(0);

        _nextPaymentDueDate = uint256(0);
        _paymentsRemaining  = uint256(0);
        _principal          = uint256(0);
    }

    /**
     *  @dev   Initializes the loan.
     *  @param borrower_    The address of the borrower.
     *  @param assets_      Array of asset addresses.
     *                          [0]: collateralAsset,
     *                          [1]: fundsAsset.
     *  @param termDetails_ Array of loan parameters:
     *                          [0]: gracePeriod,
     *                          [1]: paymentInterval,
     *                          [2]: payments,
     *  @param amounts_     Requested amounts:
     *                          [0]: collateralRequired,
     *                          [1]: principalRequested,
     *                          [2]: endingPrincipal.
     *  @param rates_       Fee parameters:
     *                          [0]: interestRate,
     *                          [1]: earlyFeeRate,
     *                          [2]: lateFeeRate,
     *                          [3]: lateInterestPremium.
     */
    function _initialize(
        address borrower_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_
    )
        internal
    {
        // Principal requested needs to be non-zero (see `_getCollateralRequiredFor` math).
        require(amounts_[1] > uint256(0), "MLI:I:INVALID_PRINCIPAL");

        // Ending principal needs to be less than or equal to principal requested.
        require(amounts_[2] <= amounts_[1], "MLI:I:INVALID_ENDING_PRINCIPAL");

        require((_borrower = borrower_) != address(0), "MLI:I:INVALID_BORROWER");

        _collateralAsset = assets_[0];
        _fundsAsset      = assets_[1];

        _gracePeriod       = termDetails_[0];
        _paymentInterval   = termDetails_[1];
        _paymentsRemaining = termDetails_[2];

        _collateralRequired = amounts_[0];
        _principalRequested = amounts_[1];
        _endingPrincipal    = amounts_[2];

        _interestRate        = rates_[0];
        _earlyFeeRate        = rates_[1];
        _lateFeeRate         = rates_[2];
        _lateInterestPremium = rates_[3];
    }

    /**************************************/
    /*** Internal Borrow-side Functions ***/
    /**************************************/

    /// @dev Prematurely ends a loan by making all remaining payments.
    function _closeLoan() internal returns (uint256 principal_, uint256 interest_) {
        require(block.timestamp <= _nextPaymentDueDate, "MLI:CL:PAYMENT_IS_LATE");

        ( principal_, interest_ ) = _getEarlyPaymentBreakdown();

        uint256 totalPaid = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        _drawableFunds = _drawableFunds + _getUnaccountedAmount(_fundsAsset) - totalPaid;

        _claimableFunds += totalPaid;

        _clearLoanAccounting();
    }

    /// @dev Sends `amount_` of `_drawableFunds` to `destination_`.
    function _drawdownFunds(uint256 amount_, address destination_) internal {
        _drawableFunds -= amount_;

        require(ERC20Helper.transfer(_fundsAsset, destination_, amount_), "MLI:DF:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                "MLI:DF:INSUFFICIENT_COLLATERAL");
    }

    /// @dev Makes a payment to progress the loan closer to maturity.
    function _makePayment() internal returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getNextPaymentBreakdown();

        uint256 totalPaid = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        // NOTE: This line will revert if not enough funds were added for the full payment amount.
        _drawableFunds = (_drawableFunds + _getUnaccountedAmount(_fundsAsset)) - totalPaid;

        _claimableFunds += totalPaid;

        uint256 paymentsRemaining = _paymentsRemaining;

        if (paymentsRemaining == uint256(1)) {
            _clearLoanAccounting();  // Assumes `_getNextPaymentBreakdown` returns a `principal_` that is `_principal`.
        } else {
            _nextPaymentDueDate += _paymentInterval;
            _principal          -= principal_;
            _paymentsRemaining   = paymentsRemaining - uint256(1);
        }
    }

    /// @dev Registers the delivery of an amount of collateral to be posted.
    function _postCollateral() internal returns (uint256 collateralPosted_) {
        _collateral += (collateralPosted_ = _getUnaccountedAmount(_collateralAsset));
    }

    /// @dev Sets refinance commitment given refinance operations.
    function _proposeNewTerms(address refinancer_, bytes[] calldata calls_) internal returns (bytes32 proposedRefinanceCommitment_) {
        // NOTE: There is no way to invalidate the `refinanceCommitment` (i.e. bytes32(0)) without explicitly setting it if `calls_.length` is 0.
        return _refinanceCommitment =
            calls_.length > uint256(0)
                ? _getRefinanceCommitment(refinancer_, calls_)
                : bytes32(0);
    }

    /// @dev Sends `amount_` of `_collateral` to `destination_`.
    function _removeCollateral(uint256 amount_, address destination_) internal {
        _collateral -= amount_;

        require(ERC20Helper.transfer(_collateralAsset, destination_, amount_), "MLI:RC:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                     "MLI:RC:INSUFFICIENT_COLLATERAL");
    }

    /// @dev Registers the delivery of an amount of funds to be returned as `_drawableFunds`.
    function _returnFunds() internal returns (uint256 fundsReturned_) {
        _drawableFunds += (fundsReturned_ = _getUnaccountedAmount(_fundsAsset));
    }

    /************************************/
    /*** Internal Lend-side Functions ***/
    /************************************/

    /// @dev Processes refinance operations.
    function _acceptNewTerms(address refinancer_, bytes[] calldata calls_) internal returns (bytes32 acceptedRefinanceCommitment_) {
        // NOTE: A zero refinancer address and/or empty calls array will never (probabilistically) match a refinance commitment in storage.
        require(_refinanceCommitment == (acceptedRefinanceCommitment_ = _getRefinanceCommitment(refinancer_, calls_)), "MLI:ANT:COMMITMENT_MISMATCH");

        require(refinancer_.code.length != uint256(0), "MLI:ANT:INVALID_REFINANCER");

        // Clear refinance commitment to prevent implications of re-acceptance of another call to `_acceptNewTerms`.
        _refinanceCommitment = bytes32(0);

        uint256 callCount = calls_.length;

        for (uint256 i; i < callCount; ++i) {
            ( bool success, ) = refinancer_.delegatecall(calls_[i]);
            require(success, "MLI:ANT:FAILED");
        }

        // Ensure that collateral is maintained after changes made.
        require(_isCollateralMaintained(), "MLI:ANT:INSUFFICIENT_COLLATERAL");
    }

    /// @dev Sends `amount_` of `_claimableFunds` to `destination_`.
    ///      If `amount_` is higher than `_claimableFunds` the transaction will underflow and revert.
    function _claimFunds(uint256 amount_, address destination_) internal {
        _claimableFunds -= amount_;

        require(ERC20Helper.transfer(_fundsAsset, destination_, amount_), "MLI:CF:TRANSFER_FAILED");
    }

    /// @dev Fund the loan and kick off the repayment requirements.
    function _fundLoan(address lender_) internal returns (uint256 fundsLent_) {
        uint256 paymentsRemaining = _paymentsRemaining;

        // Can only fund loan if there are payments remaining (as defined by the initialization) and no payment is due yet (as set by a funding).
        require((_nextPaymentDueDate == uint256(0)) && (paymentsRemaining != uint256(0)), "MLI:FL:LOAN_ACTIVE");

        uint256 paymentInterval = _paymentInterval;

        // NOTE: Don't need to check if lender_ is nonzero or valid, since it is done implicitly in calls to `lender_` below.
        _lender = lender_;

        _nextPaymentDueDate = block.timestamp + paymentInterval;

        // Amount funded and principal are as requested.
        fundsLent_ = _principal = _principalRequested;

        address fundsAsset = _fundsAsset;

        // Cannot under-fund loan, but over-funding results in additional funds left unaccounted for.
        require(_getUnaccountedAmount(fundsAsset) >= fundsLent_, "MLI:FL:WRONG_FUND_AMOUNT");

        IMapleGlobalsLike globals = IMapleGlobalsLike(IMapleLoanFactory(_factory()).mapleGlobals());

        // Transfer the annualized treasury fee, if any, to the Maple treasury, and decrement drawable funds.
        uint256 treasuryFee = (fundsLent_ * globals.treasuryFee() * paymentInterval * paymentsRemaining) / uint256(365 days * 10_000);

        // Transfer delegate fee, if any, to the pool delegate, and decrement drawable funds.
        uint256 delegateFee = (fundsLent_ * globals.investorFee() * paymentInterval * paymentsRemaining) / uint256(365 days * 10_000);

        // Drawable funds is the amount funded, minus any fees.
        _drawableFunds = fundsLent_ - treasuryFee - delegateFee;

        require(
            treasuryFee == uint256(0) || ERC20Helper.transfer(fundsAsset, globals.mapleTreasury(), treasuryFee),
            "MLI:FL:T_TRANSFER_FAILED"
        );

        require(
            delegateFee == uint256(0) || ERC20Helper.transfer(fundsAsset, ILenderLike(lender_).poolDelegate(), delegateFee),
            "MLI:FL:PD_TRANSFER_FAILED"
        );
    }

    /// @dev Reset all state variables in order to release funds and collateral of a loan in default.
    function _repossess(address destination_) internal returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_) {
        uint256 nextPaymentDueDate = _nextPaymentDueDate;

        require(
            nextPaymentDueDate != uint256(0) && (block.timestamp > nextPaymentDueDate + _gracePeriod),
            "MLI:R:NOT_IN_DEFAULT"
        );

        _clearLoanAccounting();

        // Uniquely in `_repossess`, stop accounting for all funds so that they can be swept.
        _collateral     = uint256(0);
        _claimableFunds = uint256(0);
        _drawableFunds  = uint256(0);

        address collateralAsset = _collateralAsset;

        // Either there is no collateral to repossess, or the transfer of the collateral succeeds.
        require(
            (collateralRepossessed_ = _getUnaccountedAmount(collateralAsset)) == uint256(0) ||
            ERC20Helper.transfer(collateralAsset, destination_, collateralRepossessed_),
            "MLI:R:C_TRANSFER_FAILED"
        );

        address fundsAsset = _fundsAsset;

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require(
            (fundsRepossessed_ = _getUnaccountedAmount(fundsAsset)) == uint256(0) ||
            ERC20Helper.transfer(fundsAsset, destination_, fundsRepossessed_),
            "MLI:R:F_TRANSFER_FAILED"
        );
    }

    /*******************************/
    /*** Internal View Functions ***/
    /*******************************/

    /// @dev Returns whether the amount of collateral posted is commensurate with the amount of drawn down (outstanding) principal.
    function _isCollateralMaintained() internal view returns (bool isMaintained_) {
        return _collateral >= _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);
    }

    /// @dev Get principal and interest breakdown for paying off the entire loan early.
    function _getEarlyPaymentBreakdown() internal view returns (uint256 principal_, uint256 interest_) {
        interest_ = ((principal_ = _principal) * _earlyFeeRate) / SCALED_ONE;
    }

    /// @dev Get principal and interest breakdown for next standard payment.
    function _getNextPaymentBreakdown() internal view returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getPaymentBreakdown(
            block.timestamp,
            _nextPaymentDueDate,
            _paymentInterval,
            _principal,
            _endingPrincipal,
            _paymentsRemaining,
            _interestRate,
            _lateFeeRate,
            _lateInterestPremium
        );
    }

    /// @dev Returns the amount of an `asset_` that this contract owns, which is not currently accounted for by its state variables.
    function _getUnaccountedAmount(address asset_) internal view virtual returns (uint256 unaccountedAmount_) {
        return IERC20(asset_).balanceOf(address(this))
            - (asset_ == _collateralAsset ? _collateral : uint256(0))                   // `_collateral` is `_collateralAsset` accounted for.
            - (asset_ == _fundsAsset ? _claimableFunds + _drawableFunds : uint256(0));  // `_claimableFunds` and `_drawableFunds` are `_fundsAsset` accounted for.
    }

    /*******************************/
    /*** Internal Pure Functions ***/
    /*******************************/

    /// @dev Returns the total collateral to be posted for some drawn down (outstanding) principal and overall collateral ratio requirement.
    function _getCollateralRequiredFor(
        uint256 principal_,
        uint256 drawableFunds_,
        uint256 principalRequested_,
        uint256 collateralRequired_
    )
        internal pure returns (uint256 collateral_)
    {
        // Where (collateral / outstandingPrincipal) should be greater or equal to (collateralRequired / principalRequested).
        // NOTE: principalRequested_ cannot be 0, which is reasonable, since it means this was never a loan.
        return principal_ <= drawableFunds_ ? uint256(0) : (collateralRequired_ * (principal_ - drawableFunds_)) / principalRequested_;
    }

    /// @dev Returns principal and interest portions of a payment instalment, given generic, stateless loan parameters.
    function _getInstallment(uint256 principal_, uint256 endingPrincipal_, uint256 interestRate_, uint256 paymentInterval_, uint256 totalPayments_)
        internal pure virtual returns (uint256 principalAmount_, uint256 interestAmount_)
    {
        /*************************************************************************************************\
         *                             |                                                                 *
         * A = installment amount      |      /                         \     /           R           \  *
         * P = principal remaining     |     |  /                 \      |   | ----------------------- | *
         * R = interest rate           | A = | | P * ( 1 + R ) ^ N | - E | * |   /             \       | *
         * N = payments remaining      |     |  \                 /      |   |  | ( 1 + R ) ^ N | - 1  | *
         * E = ending principal target |      \                         /     \  \             /      /  *
         *                             |                                                                 *
         *                             |---------------------------------------------------------------- *
         *                                                                                               *
         * - Where R           is `periodicRate`                                                         *
         * - Where (1 + R) ^ N is `raisedRate`                                                           *
         * - Both of these rates are scaled by 1e18 (e.g., 12% => 0.12 * 10 ** 18)                       *
        \*************************************************************************************************/

        uint256 periodicRate = _getPeriodicInterestRate(interestRate_, paymentInterval_);
        uint256 raisedRate   = _scaledExponent(SCALED_ONE + periodicRate, totalPayments_, SCALED_ONE);

        // NOTE: If a lack of precision in `_scaledExponent` results in a `raisedRate` smaller than one, assume it to be one and simplify the equation.
        if (raisedRate <= SCALED_ONE) return ((principal_ - endingPrincipal_) / totalPayments_, uint256(0));

        uint256 total = ((((principal_ * raisedRate) / SCALED_ONE) - endingPrincipal_) * periodicRate) / (raisedRate - SCALED_ONE);

        interestAmount_  = _getInterest(principal_, interestRate_, paymentInterval_);
        principalAmount_ = total >= interestAmount_ ? total - interestAmount_ : uint256(0);
    }

    /// @dev Returns an amount by applying an annualized and scaled interest rate, to a principal, over an interval of time.
    function _getInterest(uint256 principal_, uint256 interestRate_, uint256 interval_) internal pure virtual returns (uint256 interest_) {
        return (principal_ * _getPeriodicInterestRate(interestRate_, interval_)) / SCALED_ONE;
    }

    /// @dev Returns total principal and interest portion of a number of payments, given generic, stateless loan parameters and loan state.
    function _getPaymentBreakdown(
        uint256 currentTime_,
        uint256 nextPaymentDueDate_,
        uint256 paymentInterval_,
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 paymentsRemaining_,
        uint256 interestRate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremium_
    )
        internal pure virtual
        returns (uint256 principalAmount_, uint256 interestAmount_)
    {
        ( principalAmount_, interestAmount_ ) = _getInstallment(
            principal_,
            endingPrincipal_,
            interestRate_,
            paymentInterval_,
            paymentsRemaining_
        );

        principalAmount_ = paymentsRemaining_ == uint256(1) ? principal_ : principalAmount_;

        if (currentTime_ > nextPaymentDueDate_) {
            uint256 daysLate = (((currentTime_ - nextPaymentDueDate_ - 1) / 1 days) + 1) * 1 days;

            interestAmount_ += _getInterest(principal_, interestRate_ + lateInterestPremium_, daysLate);
            interestAmount_ += (lateFeeRate_ * principal_) / SCALED_ONE;
        }
    }

    /// @dev Returns the interest rate over an interval, given an annualized interest rate.
    function _getPeriodicInterestRate(uint256 interestRate_, uint256 interval_) internal pure virtual returns (uint256 periodicInterestRate_) {
        return (interestRate_ * interval_) / uint256(365 days);
    }

    /// @dev Returns refinance commitment given refinance parameters.
    function _getRefinanceCommitment(address refinancer_, bytes[] calldata calls_) internal pure returns (bytes32 refinanceCommitment_) {
        return keccak256(abi.encode(refinancer_, calls_));
    }

    /**
     *  @dev Returns exponentiation of a scaled base value.
     *
     *       Walk through example:
     *       LINE  |  base_          |  exponent_  |  one_  |  result_
     *             |  3_00           |  18         |  1_00  |  0_00
     *        A    |  3_00           |  18         |  1_00  |  1_00
     *        B    |  3_00           |  9          |  1_00  |  1_00
     *        C    |  9_00           |  9          |  1_00  |  1_00
     *        D    |  9_00           |  9          |  1_00  |  9_00
     *        B    |  9_00           |  4          |  1_00  |  9_00
     *        C    |  81_00          |  4          |  1_00  |  9_00
     *        B    |  81_00          |  2          |  1_00  |  9_00
     *        C    |  6_561_00       |  2          |  1_00  |  9_00
     *        B    |  6_561_00       |  1          |  1_00  |  9_00
     *        C    |  43_046_721_00  |  1          |  1_00  |  9_00
     *        D    |  43_046_721_00  |  1          |  1_00  |  387_420_489_00
     *        B    |  43_046_721_00  |  0          |  1_00  |  387_420_489_00
     *
     * Another implementation of this algorithm can be found in Dapphub's DSMath contract:
     * https://github.com/dapphub/ds-math/blob/ce67c0fa9f8262ecd3d76b9e4c026cda6045e96c/src/math.sol#L77
     */
    function _scaledExponent(uint256 base_, uint256 exponent_, uint256 one_) internal pure returns (uint256 result_) {
        // If exponent_ is odd, set result_ to base_, else set to one_.
        result_ = exponent_ & uint256(1) != uint256(0) ? base_ : one_;          // A

        // Divide exponent_ by 2 (overwriting itself) and proceed if not zero.
        while ((exponent_ >>= uint256(1)) != uint256(0)) {                      // B
            base_ = (base_ * base_) / one_;                                     // C

            // If exponent_ is even, go back to top.
            if (exponent_ & uint256(1) == uint256(0)) continue;

            // If exponent_ is odd, multiply result_ is multiplied by base_.
            result_ = (result_ * base_) / one_;                                 // D
        }
    }

}
