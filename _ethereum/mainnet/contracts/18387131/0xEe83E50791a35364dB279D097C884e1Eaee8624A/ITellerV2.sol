// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITellerV2 {
    struct LoanDetails {
        address lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
    }

    struct Terms {
        uint256 paymentCycleAmount;
        uint32 paymentCycle;
        uint16 APR;
    }

    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    function approveMarketForwarder(uint256 _marketId, address _forwarder)
        external;

    function calculateAmountOwed(uint256 _bidId, uint256 _timestamp)
        external
        view
        returns (Payment memory owed);

    function calculateNextDueDate(uint256 _bidId)
        external
        view
        returns (uint32 dueDate_);

    function collateralManager() external view returns (address);

    function hasApprovedMarketForwarder(
        uint256 _marketId,
        address _forwarder,
        address _account
    ) external view returns (bool);

    function lenderCommitmentForwarder() external view returns (address);

    function marketRegistry() external view returns (address);

    function protocolFee() external view returns (uint16);

    function repayLoanFull(uint256 _bidId) external;
}