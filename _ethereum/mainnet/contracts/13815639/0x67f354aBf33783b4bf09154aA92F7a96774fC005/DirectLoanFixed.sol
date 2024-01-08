// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./DirectLoanBase.sol";
import "./ContractKeys.sol";

/**
 * @title  DirectLoanFixed
 * @author NFTfi
 * @notice Main contract for NFTfi Direct Loans Fixed Type. This contract manages the ability to create NFT-backed
 * peer-to-peer loans of type Fixed (agreed to be a fixed-repayment loan) where the borrower pays the
 * maximumRepaymentAmount regardless of whether they repay early or not.
 *
 * There are two ways to commence an NFT-backed loan:
 *
 * a. The borrower accepts a lender's offer by calling `acceptOffer`.
 *   1. the borrower calls nftContract.approveAll(NFTfi), approving the NFTfi contract to move their NFT's on their
 * be1alf.
 *   2. the lender calls erc20Contract.approve(NFTfi), allowing NFTfi to move the lender's ERC20 tokens on their
 * behalf.
 *   3. the lender signs an off-chain message, proposing its offer terms.
 *   4. the borrower calls `acceptOffer` to accept these terms and enter into the loan. The NFT is stored in
 * the contract, the borrower receives the loan principal in the specified ERC20 currency, the lender receives an
 * NFTfi promissory note (in ERC721 form) that represents the rights to either the principal-plus-interest, or the
 * underlying NFT collateral if the borrower does not pay back in time, and the borrower receives obligation receipt
 * (in ERC721 form) that gives them the right to pay back the loan and get the collateral back.
 *
 * b. The lender accepts a borrowe's binding terms by calling `acceptListing`.
 *   1. the borrower calls nftContract.approveAll(NFTfi), approving the NFTfi contract to move their NFT's on their
 * be1alf.
 *   2. the lender calls erc20Contract.approve(NFTfi), allowing NFTfi to move the lender's ERC20 tokens on their
 * behalf.
 *   3. the borrower signs an off-chain message, proposing its binding terms.
 *   4. the lender calls `acceptListing` with an offer matching the binding terms and enter into the loan. The NFT is
 * stored in the contract, the borrower receives the loan principal in the specified ERC20 currency, the lender
 * receives an NFTfi promissory note (in ERC721 form) that represents the rights to either the principal-plus-interest,
 * or the underlying NFT collateral if the borrower does not pay back in time, and the borrower receives obligation
 * receipt (in ERC721 form) that gives them the right to pay back the loan and get the collateral back.
 *
 * The lender can freely transfer and trade this ERC721 promissory note as they wish, with the knowledge that
 * transferring the ERC721 promissory note tranfsers the rights to principal-plus-interest and/or collateral, and that
 * they will no longer have a claim on the loan. The ERC721 promissory note itself represents that claim.
 *
 * The borrower can freely transfer and trade this ERC721 obligaiton receipt as they wish, with the knowledge that
 * transferring the ERC721 obligaiton receipt tranfsers the rights right to pay back the loan and get the collateral
 * back.
 *
 *
 * A loan may end in one of two ways:
 * - First, a borrower may call NFTfi.payBackLoan() and pay back the loan plus interest at any time, in which case they
 * receive their NFT back in the same transaction.
 * - Second, if the loan's duration has passed and the loan has not been paid back yet, a lender can call
 * NFTfi.liquidateOverdueLoan(), in which case they receive the underlying NFT collateral and forfeit the rights to the
 * principal-plus-interest, which the borrower now keeps.
 */
contract DirectLoanFixed is DirectLoanBase {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    bytes32 public constant LOAN_TYPE = bytes32("DIRECT_LOAN_FIXED");

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @dev Sets `hub`
     *
     * @param _admin - Initial admin of this contract.
     * @param  _nftfiHub - NFTfiHub address
     */
    // le paso el id del direct loan coordinator
    constructor(address _admin, address _nftfiHub)
        DirectLoanBase(_admin, _nftfiHub, ContractKeys.getIdFromStringKey("DIRECT_LOAN_COORDINATOR"))
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice This function is called by the borrower when accepting a lender's offer to begin a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _signature - The components of the lender's signature.
     * @param _borrowerSettings - Some extra parameters that the borrower needs to set when accepting an offer.
     */
    function acceptOffer(
        Offer memory _offer,
        Signature memory _signature,
        BorrowerSettings memory _borrowerSettings
    ) external whenNotPaused nonReentrant {
        address nftWrapper = _getWrapper(_offer.nftCollateralContract);
        LoanChecksAndCalculations.loanSanityChecks(_offer, nftWrapper, hub);
        LoanChecksAndCalculations.loanSanityChecksOffer(_offer);
        _acceptOffer(
            LOAN_TYPE,
            _setupLoanTermsOffer(_offer, nftWrapper),
            _setupLoanExtras(_borrowerSettings.revenueSharePartner, _borrowerSettings.referralFeeInBasisPoints),
            _offer,
            _signature
        );
    }

    /**
     * @notice This function is called by the borrower when accepting a lender's offer to begin a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _signature - The components of the lender's signature.
     * @param _borrowerSettings - Some extra parameters that the borrower needs to set when accepting an offer.
     * @param _bundleElements - the lists of erc721-20-1155 tokens that are to be bundled
     */
    function acceptBundleOffer(
        Offer memory _offer,
        Signature memory _signature,
        BorrowerSettings memory _borrowerSettings,
        IBundleBuilder.BundleElements memory _bundleElements
    ) external whenNotPaused nonReentrant {
        address nftWrapper = _getWrapper(_offer.nftCollateralContract);
        LoanChecksAndCalculations.loanSanityChecks(_offer, nftWrapper, hub);
        LoanChecksAndCalculations.loanSanityChecksOffer(_offer);
        _acceptBundleOffer(
            LOAN_TYPE,
            _setupLoanTermsOffer(_offer, nftWrapper),
            _setupLoanExtras(_borrowerSettings.revenueSharePartner, _borrowerSettings.referralFeeInBasisPoints),
            _offer,
            _bundleElements,
            _signature
        );
    }

    /**
     * @notice This function is called by the lender when accepting a barrower's binding terms for a loan.
     *
     * @param _listingTerms - Terms the borrower set off-chain and is willing to accept automatically when
     * fulfiled by a lender's offer .
     * @param _offer - The offer made by the lender.
     * @param _signature - The components of the borrower's signature.
     */
    function acceptListing(
        ListingTerms memory _listingTerms,
        Offer memory _offer,
        Signature memory _signature
    ) external whenNotPaused nonReentrant {
        address nftWrapper = _getWrapper(_offer.nftCollateralContract);
        LoanChecksAndCalculations.loanSanityChecks(_offer, nftWrapper, hub);
        LoanChecksAndCalculations.bindingTermsSanityChecks(_listingTerms, _offer);
        _acceptListing(
            LOAN_TYPE,
            _setupLoanTermsListing(_offer, nftWrapper),
            _setupLoanExtras(_listingTerms.revenueSharePartner, _listingTerms.referralFeeInBasisPoints),
            _listingTerms,
            _offer.referrer,
            _signature
        );
    }

    /**
     * @notice This function is called by the lender when accepting a barrower's binding terms for a loan.
     *
     * @param _listingTerms - Terms the borrower set off-chain and is willing to accept automatically when
     * fulfiled by a lender's offer .
     * @param _offer - The offer made by the lender.
     * @param _signature - The components of the borrower's signature.
     * @param _bundleElements - the lists of erc721-20-1155 tokens that are to be bundled
     */
    function acceptBundleListing(
        ListingTerms memory _listingTerms,
        Offer memory _offer,
        Signature memory _signature,
        IBundleBuilder.BundleElements memory _bundleElements
    ) external whenNotPaused nonReentrant {
        address nftWrapper = _getWrapper(_offer.nftCollateralContract);
        LoanChecksAndCalculations.loanSanityChecks(_offer, nftWrapper, hub);
        LoanChecksAndCalculations.bindingTermsSanityChecks(_listingTerms, _offer);
        _acceptBundleListing(
            LOAN_TYPE,
            _setupLoanTermsListing(_offer, nftWrapper),
            _setupLoanExtras(_listingTerms.revenueSharePartner, _listingTerms.referralFeeInBasisPoints),
            _listingTerms,
            _offer.referrer,
            _bundleElements,
            _signature
        );
    }

    /**
     * @dev makes possible to change loan duration and max repayment amount, loan duration even can be extended if
     * loan was expired but not liquidated.
     *
     * @param _loanId - The unique identifier for the loan to be renegotiated
     * @param _newLoanDuration - The new amount of time (measured in seconds) that can elapse before the lender can
     * liquidate the loan and seize the underlying collateral NFT.
     * @param _newMaximumRepaymentAmount - The new maximum amount of money that the borrower would be required to
     * retrieve their collateral, measured in the smallest units of the ERC20 currency used for the loan. The
     * borrower will always have to pay this amount to retrieve their collateral, regardless of whether they repay
     * early.
     * @param _renegotiationFee Agreed upon fee in ether that borrower pays for the lender for the renegitiation
     * @param _lenderNonce - The nonce referred to here is not the same as an Ethereum account's nonce. We are
     * referring instead to nonces that are used by both the lender and the borrower when they are first signing
     * off-chain NFTfi orders. These nonces can be any uint256 value that the user has not previously used to sign an
     * off-chain order. Each nonce can be used at most once per user within NFTfi, regardless of whether they are the
     * lender or the borrower in that situation. This serves two purposes:
     * - First, it prevents replay attacks where an attacker would submit a user's off-chain order more than once.
     * - Second, it allows a user to cancel an off-chain order by calling NFTfi.cancelLoanCommitmentBeforeLoanHasBegun()
     * , which marks the nonce as used and prevents any future loan from using the user's off-chain order that contains
     * that nonce.
     * @param _expiry - The date when the renegotiation offer expires
     * @param _lenderSignature - The ECDSA signature of the lender, obtained off-chain ahead of time, signing the
     * following combination of parameters:
     * - _loanId
     * - _newLoanDuration
     * - _newMaximumRepaymentAmount
     * - _lender
     * - _expiry
     *  - address of this contract
     * - chainId
     */
    function renegotiateLoan(
        uint256 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _renegotiationFee,
        uint256 _lenderNonce,
        uint256 _expiry,
        bytes memory _lenderSignature
    ) external whenNotPaused nonReentrant {
        _renegotiateLoan(
            _loanId,
            _newLoanDuration,
            _newMaximumRepaymentAmount,
            _renegotiationFee,
            _lenderNonce,
            _expiry,
            _lenderSignature
        );
    }

    /* ******************* */
    /* READ-ONLY FUNCTIONS */
    /* ******************* */

    /**
     * @notice This function can be used to view the current quantity of the ERC20 currency used in the specified loan
     * required by the borrower to repay their loan, measured in the smallest unit of the ERC20 currency.
     *
     * @param _loanId  A unique identifier for this particular loan, sourced from the Loan Coordinator.
     *
     * @return The amount of the specified ERC20 currency required to pay back this loan, measured in the smallest unit
     * of the specified ERC20 currency.
     */
    function getPayoffAmount(uint256 _loanId) external view override returns (uint256) {
        LoanTerms storage loan = loanIdToLoan[_loanId];
        return loan.maximumRepaymentAmount;
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    /**
     * @dev Creates a `LoanTerms` struct using data sent as the lender's `_offer` on `acceptOffer`.
     * This is needed in order to avoid stack too deep issues.
     * Since this is a Fixed loan type loanInterestRateForDurationInBasisPoints is ignored.
     */
    function _setupLoanTermsOffer(Offer memory _offer, address _nftWrapper) internal view returns (LoanTerms memory) {
        return
            LoanTerms({
                loanERC20Denomination: _offer.loanERC20Denomination,
                loanPrincipalAmount: _offer.loanPrincipalAmount,
                maximumRepaymentAmount: _offer.maximumRepaymentAmount,
                nftCollateralContract: _offer.nftCollateralContract,
                nftCollateralWrapper: _nftWrapper,
                nftCollateralId: _offer.nftCollateralId,
                loanStartTime: uint64(block.timestamp),
                loanDuration: _offer.loanDuration,
                loanInterestRateForDurationInBasisPoints: uint16(0),
                loanAdminFeeInBasisPoints: _offer.loanAdminFeeInBasisPoints
            });
    }

    /**
     * @dev Creates a `LoanTerms` struct using data sent as the lender's `_offer` on `acceptListing`.
     * Even though this is a Fixed type loan, this is called when the lender is accepting the binding terms set by the
     * borrower so the `maximumRepaymentAmount` should be calculated based on the offer's `loanPrincipalAmount` and
     * `loanInterestRateForDurationInBasisPoints`
     * This is needed in order to avoid stack too deep issues.
     */
    function _setupLoanTermsListing(Offer memory _offer, address _nftWrapper) internal view returns (LoanTerms memory) {
        return
            LoanTerms({
                loanERC20Denomination: _offer.loanERC20Denomination,
                loanPrincipalAmount: _offer.loanPrincipalAmount,
                maximumRepaymentAmount: _offer.maximumRepaymentAmount,
                nftCollateralContract: _offer.nftCollateralContract,
                nftCollateralWrapper: _nftWrapper,
                nftCollateralId: _offer.nftCollateralId,
                loanStartTime: uint64(block.timestamp),
                loanDuration: _offer.loanDuration,
                loanInterestRateForDurationInBasisPoints: uint16(0),
                loanAdminFeeInBasisPoints: _offer.loanAdminFeeInBasisPoints
            });
    }

    /**
     * @dev Calculates the payoff amount and admin fee
     *
     * @param _loanTerms - Struct containing all the loan's parameters
     */
    function _payoffAndFee(LoanTerms memory _loanTerms)
        internal
        pure
        override
        returns (uint256 adminFee, uint256 payoffAmount)
    {
        // Calculate amounts to send to lender and admins
        uint256 interestDue = _loanTerms.maximumRepaymentAmount - _loanTerms.loanPrincipalAmount;
        adminFee = LoanChecksAndCalculations.computeAdminFee(
            interestDue,
            uint256(_loanTerms.loanAdminFeeInBasisPoints)
        );
        payoffAmount = _loanTerms.maximumRepaymentAmount - adminFee;
    }
}
