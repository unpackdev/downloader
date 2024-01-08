// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC165.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./LoanLibrary.sol";
import "./IPromissoryNote.sol";
import "./ILoanCore.sol";
import "./IRepaymentController.sol";

contract RepaymentController is IRepaymentController {
    using SafeMath for uint256;

    ILoanCore private loanCore;
    IPromissoryNote private borrowerNote;
    IPromissoryNote private lenderNote;

    constructor(
        ILoanCore _loanCore,
        IPromissoryNote _borrowerNote,
        IPromissoryNote _lenderNote
    ) {
        loanCore = _loanCore;
        borrowerNote = _borrowerNote;
        lenderNote = _lenderNote;
    }

    /**
     * @inheritdoc IRepaymentController
     */
    function repay(uint256 borrowerNoteId) external override {
        // get loan from borrower note
        uint256 loanId = borrowerNote.loanIdByNoteId(borrowerNoteId);

        require(loanId != 0, "RepaymentController: repay could not dereference loan");

        LoanLibrary.LoanTerms memory terms = loanCore.getLoan(loanId).terms;

        // withdraw principal plus interest from borrower and send to loan core
        SafeERC20.safeTransferFrom(
            IERC20(terms.payableCurrency),
            msg.sender,
            address(this),
            terms.principal.add(terms.interest)
        );
        IERC20(terms.payableCurrency).approve(address(loanCore), terms.principal.add(terms.interest));

        // call repay function in loan core
        loanCore.repay(loanId);
    }

    /**
     * @inheritdoc IRepaymentController
     */
    function claim(uint256 lenderNoteId) external override {
        // make sure that caller owns lender note
        address lender = lenderNote.ownerOf(lenderNoteId);
        require(lender == msg.sender, "RepaymentController: not owner of lender note");

        // get loan from lender note
        uint256 loanId = lenderNote.loanIdByNoteId(lenderNoteId);
        require(loanId != 0, "RepaymentController: claim could not dereference loan");

        // call claim function in loan core
        loanCore.claim(loanId);
    }
}
