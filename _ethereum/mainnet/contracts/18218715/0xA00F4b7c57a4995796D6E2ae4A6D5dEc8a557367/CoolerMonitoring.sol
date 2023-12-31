// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICooler {

    struct Request {
        uint256 amount;             // Amount to be borrowed.
        uint256 interest;           // Annualized percentage to be paid as interest.
        uint256 loanToCollateral;   // Requested loan-to-collateral ratio.
        uint256 duration;           // Time to repay the loan before it defaults.
        bool active;                // Any lender can clear an active loan request.
        address requester;          // The address that created the request.
    }

    struct Loan {
        Request request;        // Loan terms specified in the request.
        uint256 principal;      // Amount of principal debt owed to the lender.
        uint256 interestDue;    // Interest owed to the lender.
        uint256 collateral;     // Amount of collateral pledged.
        uint256 expiry;         // Time when the loan defaults.
        address lender;         // Lender's address.
        address recipient;      // Recipient of repayments.
        bool callback;          // If this is true, the lender must inherit CoolerCallback.
    }

    function getLoan(uint256 loanID_) external view returns (Loan memory);
}

contract CoolerMonitoring {
    function timeToExpiry(address cooler_, uint256 id_) public view returns (uint256 timeLeft){
        ICooler.Loan memory loan = ICooler(cooler_).getLoan(id_);

        return (loan.expiry > block.timestamp) ? loan.expiry - block.timestamp : 0;
    }
}

