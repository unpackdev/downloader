// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Errors library
 * @author ERD
 * @notice Defines the error messages emitted by the different contracts of the ERD protocol
 * @dev Error messages prefix glossary:
 *  - AP = ActivePool
 *  - BO = BorrowerOperations
 *  - CM = CollateralManager
 *  - CSP = CollSurplusPool
 *  - DP = DefaultPool
 *  - ET = EToken
 *  - ST = SortedTroves
 *  - SP = StabilityPool
 *  - TD = TroveDebt
 *  - TM = TroveManager
 *  - TML = TroveManagerLiquidations
 *  - TMR = TroveManagerRedemptions
 *  - CE = Common Error
 *  - P = Pausable
 *  - CALLER = Caller
 */
library Errors {
    //common errors
    error NotContract(); // 'Contract check error'
    error ProtocolPaused(); // 'Protocol paused'
    error LengthMismatch(); // 'Length mismatch'
    error SendETHFailed();
    error ZeroValue();
    error OwnershipCannotBeRenounced();

    error Caller_NotAP(); // 'Caller is not ActivePool'
    error Caller_NotBO(); // 'Caller is not BorrowerOperations'
    error Caller_NotCM(); // 'Caller is not CollateralManager'
    error Caller_NotSP(); // 'Caller is not Stability Pool'
    error Caller_NotTM(); // 'Caller is not TroveManager'
    error Caller_NotTML(); // 'Caller is not TroveManagerLiquidations'
    error Caller_NotTMR(); // 'Caller is not TroveManagerRedemptions'
    error Caller_NotTMLOrTMR(); // 'Caller is neither TroveManagerLiquidations nor TroveManagerRedemptions'
    error Caller_NotBOOrTM(); // 'Caller is neither BorrowerOperations nor TroveManager'
    error Caller_NotBOOrTMR(); // 'Caller is neither BorrowerOperations nor TroveManagerLiquidations nor TroveManagerRedemptions'
    error Caller_NotBOOrTMLOrTMR(); // 'Caller is neither BorrowerOperations nor TroveManagerRedemptions'
    error Caller_NotBOOrTMOrSPOrTMLOrTMR(); // 'Caller is neither BorrowerOperations nor TroveManager nor StabilityPool nor TMR nor TML'
    error Caller_NotBorrowerOrSP(); // 'Caller is neither borrower nor StabilityPool'

    //contract specific errors
    error BO_TroveIsActive(); // 'Trove is active'
    error BO_DebtIncreaseZero(); // 'Debt increase requires non-zero debtChange'
    error BO_NotPermitInRM(); // 'Operation not permitted during Recovery Mode'
    error BO_LengthZero(); // 'Length is zero'
    error BO_ETHNotActiveOrPaused(); // 'ETH does not active or is paused'
    error BO_CollNotActiveOrPaused(); // 'Collateral does not active or is paused'
    error BO_CollAmountZero(); // 'Collateral amount is 0'
    error BO_ETHNotActive(); // 'ETH does not active'
    error BO_CollNotActive(); // 'Collateral does not active'
    error BO_CollNotActiveOrNotSupported(); // 'Collateral does not support or active'
    error BO_CollsOverlap(); // 'Overlap Colls'
    error BO_CollsDuplicate(); // 'Duplicate Colls'
    error BO_CollsCannotContainWETH(); // 'Cannot withdraw and add WETH'
    error BO_MustChangeForCollOrDebt(); // 'There must be either a collateral change or a debt change'
    error BO_TroveNotExistOrClosed(); // 'Trove does not exist or is closed'
    error BO_CollsCannotWithdrawalInRM(); // 'Collateral withdrawal not permitted Recovery Mode'
    error BO_CannotDecreaseICRInRM(); // 'Cannot decrease your Trove's ICR in Recovery Mode'
    error BO_ICRLessThanMCR(); // 'An operation that would result in ICR < MCR is not permitted'
    error BO_ICRLessThanCCR(); // 'Operation must leave trove with ICR >= CCR'
    error BO_TCRLessThanCCR(); // 'An operation that would result in TCR < CCR is not permitted'
    error BO_TroveDebtLessThanMinDebt(); // 'Trove's net debt must be greater than minimum'
    error BO_USDEInsufficient(); // 'Caller doesnt have enough USDE to make repayment'
    error BO_MaxFeeExceed100(); // 'Max fee percentage must less than or equal to 100%'
    error BO_BadMaxFee(); // 'Max fee percentage must be between 0.25% and 100%'
    error BO_ExceedMarketCap();

    error CM_CollExists(); // 'Collateral already exists'
    error CM_CollNotPaused(); // 'Collateral not pause'
    error CM_NoMoreColl(); // 'Need at least one collateral support'
    error CM_CollNotSupported(); // 'Collateral not support'
    error CM_CollNotActive(); // 'Collateral not active'
    error CM_BadValue(); // 'Value not in the right range'

    error CSP_CannotClaim(); // 'No collateral available to claim'

    error ET_NotSupported();

    error PF_ChainlinkNotWork();

    error ST_SizeZero(); // 'Size can't be zero'
    error ST_ListFull(); // 'List is full'
    error ST_ListContainsNode(); // 'List already contains the node'
    error ST_ListNotContainsNode(); // 'List does not contain the id'
    error ST_ZeroAddress(); // 'ICR must be positive'
    error ST_ZeroICR(); // 'Id cannot be zero'

    error SP_ZeroValue();
    error SP_BadDebtOffset();
    error SP_USDELossGreaterThanOne(); // 'USDELoss > 1'
    error SP_WithdrawWithICRLessThanMCR(); // 'Cannot withdraw while there are troves with ICR < MCR'
    error SP_NoDepositBefore(); // 'User must have a non-zero deposit'
    error SP_HadDeposit(); // 'User must have no deposit'
    error SP_CallerTroveNotActive(); // "Caller must have an active trove to withdraw collater Gain to"
    error SP_ZeroGain(); // 'Caller must have non-zero Collateral Gain'
    error SP_AlreadyRegistered(); // 'Must not already be a registered front end'
    error SP_MustRegisteredOrZeroAddress(); // 'Tag must be a registered front end, or the zero address'
    error SP_BadKickbackRate(); // 'Kickback rate must be in range [0,1]'

    error TD_ZeroValue(); // 'Invalid mint amount'

    error TM_ZeroValue();
    error TM_BadValue();
    error TM_BadClosedStatus();
    error TM_BadBorrowRate();
    error TM_BadBorrowIndex();
    error TM_OnlyOneTroveLeft(); //  'Only one trove in the system'
    error TM_BadBaseRate(); //  'newBaseRate must be > 0'
    error TM_BadFee(); //  'Fee would eat up all returned collateral'
    error TM_TroveNotExistOrClosed(); //  'Trove does not exist or is closed'

    error TML_NoUSDEInSP();
    error TML_NothingToLiquidate();
    error TML_EmptyArray();

    error TMR_BadUSDEBalance(); // 'Confirm redeemer's balance is less than total USDE supply'
    error TMR_CannotRedeem(); // 'Unable to redeem any amount'
    error TMR_RedemptionAmountExceedBalance(); // 'Requested redemption amount must be <= user's USDE token balance'
    error TMR_ZeroValue(); // 'Amount must be greater than zero'
    error TMR_CannotRedeemWhenTCRLessThanMCR(); // 'Cannot redeem when TCR < MCR'
    error TMR_RedemptionNotAllowed(); // 'Redemptions are not allowed during bootstrap phase'
    error TMR_BadMaxFee(); // 'Max fee percentage must be in the right range'
}
