//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity 0.8.10;
//SPDX-License-Identifier: MIT

library Errors {
    // Access control errors
    error CallerNotController();
    error CallerNotAllowedPool();
    error CallerNotMinter();
    error CallerNotImplementation();

    // ERC20 type errors
    error FailTransfer();
    error FailTransferFrom();
    error BalanceTooLow();
    error AllowanceTooLow();
    error AllowanceUnderflow();
    error SelfTransfer();

    // PalPool errors
    error InsufficientCash();
    error InsufficientBalance();
    error FailDeposit();
    error FailLoanInitiate();
    error FailBorrow();
    error ZeroBorrow();
    error BorrowInsufficientFees();
    error LoanClosed();
    error NotLoanOwner();
    error LoanOwner();
    error FailLoanExpand();
    error NotKillable();
    error ReserveFundsInsufficient();
    error FailMint();
    error FailBurn();
    error FailWithdraw();
    error FailCloseBorrow();
    error FailKillBorrow();
    error ZeroAddress();
    error InvalidParameters(); 
    error FailLoanDelegateeChange();
    error FailLoanTokenBurn();
    error FeesAccruedInsufficient();
    error CallerNotMotherPool();
    error AlreadyInitialized();
    error MultiplierAlreadyActivated();
    error MultiplierNotActivated();
    error FailPoolClaim();
    error FailUpdateInterest();
    error InvalidToken();
    error InvalidAmount();


    //Controller errors
    error ListSizesNotEqual();
    error PoolListAlreadySet();
    error PoolAlreadyListed();
    error PoolNotListed();
    error CallerNotPool();
    error RewardsCashTooLow();
    error FailBecomeImplementation();
    error InsufficientDeposited();
    error NotClaimable();
    error Locked();
}