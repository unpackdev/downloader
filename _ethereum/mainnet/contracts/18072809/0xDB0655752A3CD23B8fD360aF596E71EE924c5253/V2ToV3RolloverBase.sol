// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./IMigrationBase.sol";

import "./RolloverErrors.sol";

/**
 * @title V2ToV3RolloverBase
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract holds the common logic for the V2ToV3Rollover and V2ToV3RolloverWithItems contracts.
 */
abstract contract V2ToV3RolloverBase is IMigrationBase, ReentrancyGuard, ERC721Holder, Ownable {
    using SafeERC20 for IERC20;

    event V2V3Rollover(
        address indexed lender,
        address indexed borrower,
        uint256 collateralTokenId,
        uint256 newLoanId
    );

    struct OperationContracts {
        ILoanCoreV2 loanCoreV2;
        IERC721 borrowerNoteV2;
        IRepaymentControllerV2 repaymentControllerV2;
        IFeeController feeControllerV3;
        IOriginationController originationControllerV3;
        ILoanCore loanCoreV3;
        IERC721 borrowerNoteV3;
    }

    // Balancer vault contract
    /* solhint-disable var-name-mixedcase */
    IVault public immutable VAULT; // 0xBA12222222228d8Ba445958a75a0704d566BF2C8

    /// @notice lending protocol contract references
    ILoanCoreV2 public immutable loanCoreV2;
    IERC721 public immutable borrowerNoteV2;
    IRepaymentControllerV2 public immutable repaymentControllerV2;
    IFeeController public immutable feeControllerV3;
    IOriginationController public immutable originationControllerV3;
    ILoanCore public immutable loanCoreV3;
    IERC721 public immutable borrowerNoteV3;

    /// @notice State variable used for checking the inheriting contract initiated the flash
    ///         loan. When a rollover function is called the borrowers address is cached here
    ///         and checked against the opData in the flash loan callback.
    address public borrower;

    /// @notice state variable for pausing the contract
    bool public paused;

    constructor(IVault _vault, OperationContracts memory _opContracts) {
        // input sanitization
        if (address(_vault) == address(0)) revert R_ZeroAddress("vault");
        if (address(_opContracts.loanCoreV2) == address(0)) revert R_ZeroAddress("loanCoreV2");
        if (address(_opContracts.borrowerNoteV2) == address(0)) revert R_ZeroAddress("borrowerNoteV2");
        if (address(_opContracts.repaymentControllerV2) == address(0)) revert R_ZeroAddress("repaymentControllerV2");
        if (address(_opContracts.feeControllerV3) == address(0)) revert R_ZeroAddress("feeControllerV3");
        if (address(_opContracts.originationControllerV3) == address(0)) revert R_ZeroAddress("originationControllerV3");
        if (address(_opContracts.loanCoreV3) == address(0)) revert R_ZeroAddress("loanCoreV3");
        if (address(_opContracts.borrowerNoteV3) == address(0)) revert R_ZeroAddress("borrowerNoteV3");

        // Set Balancer vault address
        VAULT = _vault;

        // Set lending protocol contract references
        loanCoreV2 = ILoanCoreV2(_opContracts.loanCoreV2);
        borrowerNoteV2 = IERC721(_opContracts.borrowerNoteV2);
        repaymentControllerV2 = IRepaymentControllerV2(_opContracts.repaymentControllerV2);
        feeControllerV3 = IFeeController(_opContracts.feeControllerV3);
        originationControllerV3 = IOriginationController(_opContracts.originationControllerV3);
        loanCoreV3 = ILoanCore(_opContracts.loanCoreV3);
        borrowerNoteV3 = IERC721(_opContracts.borrowerNoteV3);
    }

    /**
     * @notice This helper function to calculate the net amounts required to repay the flash loan.
     *         This function will return the total amount due back to the lending pool. The amount
     *         that needs to be paid by the borrower, in the case that the new loan does not cover
     *         the flashAmountDue. Lastly, the amount that will be sent back to the borrower, in
     *         the case that the new loan covers more than the flashAmountDue. There cannot be a
     *         case where both needFromBorrower and leftoverPrincipal are non-zero.
     *
     * @param amount                  The amount that was borrowed in Flash Loan.
     * @param premium                 The fees that are due back to the lending pool.
     * @param originationFee          The origination fee for the new loan.
     * @param newPrincipal            The principal of the new loan.
     *
     * @return flashAmountDue         The total amount due back to the lending pool.
     * @return needFromBorrower       The amount borrower owes if new loan cannot repay flash loan.
     * @return leftoverPrincipal      The amount to send to borrower if new loan amount is more than
     *                                amount required to repay flash loan.
     */
    function _ensureFunds(
        uint256 amount,
        uint256 premium,
        uint256 originationFee,
        uint256 newPrincipal
    ) internal pure returns (uint256 flashAmountDue, uint256 needFromBorrower, uint256 leftoverPrincipal) {
        // total amount due to flash loan contract
        flashAmountDue = amount + premium;
        // amount that will be received when starting the new loan
        uint256 willReceive = newPrincipal - ((newPrincipal * originationFee) / 1e4);

        if (flashAmountDue > willReceive) {
            // Not enough - have borrower pay the difference
            unchecked {
                needFromBorrower = flashAmountDue - willReceive;
            }
        } else if (willReceive > flashAmountDue) {
            // Too much - will send extra to borrower
            unchecked {
                leftoverPrincipal = willReceive - flashAmountDue;
            }
        }
    }

    /**
     * @notice Helper function to repay the loan. Takes the borrowerNote from the borrower, approves
     *         the V2 repayment controller to spend the payable currency received from flash loan.
     *         Repays the loan, and ensures this contract holds the collateral after the loan is repaid.
     *
     * @param loanData                 The loan data for the loan to be repaid.
     * @param borrowerNoteId           ID of the borrowerNote for the loan to be repaid.
     * @param opDataBorrower           The address of the borrower.
     */
    function _repayLoan(
        LoanLibraryV2.LoanData memory loanData,
        uint256 borrowerNoteId,
        address opDataBorrower
    ) internal {
        // take BorrowerNote from borrower so that this contract receives collateral
        // borrower must approve this withdrawal
        borrowerNoteV2.transferFrom(opDataBorrower, address(this), borrowerNoteId);

        // approve repayment
        uint256 totalRepayment = repaymentControllerV2.getFullInterestAmount(
            loanData.terms.principal,
            loanData.terms.interestRate
        );

        IERC20(loanData.terms.payableCurrency).approve(
            address(repaymentControllerV2),
            totalRepayment
        );

        // repay loan
        repaymentControllerV2.repay(borrowerNoteId);

        // contract now has collateral but has lost funds
        address collateralOwner = IERC721(loanData.terms.collateralAddress).ownerOf(loanData.terms.collateralId);
        if (collateralOwner != address(this)) revert R_NotCollateralOwner(collateralOwner);
    }

    /**
     * @notice Validates that the rollover is valid. The borrower from the old loan must be the caller.
     *         The new loan must have the same currency as the old loan. The new loan must use the same
     *         collateral as the old loan. If any of these conditionals are not met, the transaction
     *         will revert.
     *
     * @param sourceLoanTerms           The terms of the V2 loan.
     * @param newLoanTerms              The terms of the V3 loan.
     * @param borrowerNoteId            The ID of the borrowerNote for the old loan.
     *
     * @return _borrower                Caller and the owner of borrowerNote address.
     */
    function _validateRollover(
        LoanLibraryV2.LoanTerms memory sourceLoanTerms,
        LoanLibrary.LoanTerms memory newLoanTerms,
        uint256 borrowerNoteId
    ) internal view returns (address _borrower) {
        _borrower = borrowerNoteV2.ownerOf(borrowerNoteId);

        if (_borrower != msg.sender) revert R_CallerNotBorrower(msg.sender, _borrower);

        if (sourceLoanTerms.payableCurrency != newLoanTerms.payableCurrency) {
            revert R_CurrencyMismatch(sourceLoanTerms.payableCurrency, newLoanTerms.payableCurrency);
        }

        if (sourceLoanTerms.collateralAddress != newLoanTerms.collateralAddress) {
            revert R_CollateralMismatch(sourceLoanTerms.collateralAddress, newLoanTerms.collateralAddress);
        }

        if (sourceLoanTerms.collateralId != newLoanTerms.collateralId) {
            revert R_CollateralIdMismatch(sourceLoanTerms.collateralId, newLoanTerms.collateralId);
        }
    }

    /**
     * @notice Function to be used by the contract owner to pause the contract.
     *
     * @dev This function is only to be used if a vulnerability is found or the contract
     *      is no longer being used.
     *
     * @param _pause              The state to set the contract to.
     */
    function pause(bool _pause) external override onlyOwner {
        if (paused == _pause) revert R_StateAlreadySet();

        paused = _pause;

        emit PausedStateChanged(_pause);
    }

    /**
     * @notice Function to be used by the contract owner to withdraw any ERC20 tokens that
     *         are sent to the contract and get stuck.
     */
    function flushToken(IERC20 token, address to) external override onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert R_NoTokenBalance();

        token.safeTransfer(to, balance);
    }

    /**
     * @notice This function ensures that at the start of every flash loan sequence, the borrower
     *         state is reset to address(0). The rollover functions that inherit this modifier set
     *         the borrower state while executing the rollover operations. At the end of the rollover
     *         the borrower state is reset to address(0).
     */
    modifier whenBorrowerReset() {
        if (borrower != address(0)) revert R_BorrowerNotReset(borrower);

        _;

        borrower = address(0);
    }
}
