// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

// Interfaces
import "./IMarketRegistry.sol";
import "./ICollateralManager.sol";

interface ITellerV2 {
    function bidId() external view returns (uint256);

    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    function calculateAmountOwed(
        uint256 _bidId,
        uint256 _timestamp
    ) external view returns (Payment memory owed);

    function repayLoanFull(uint256 _bidId) external;

    function hasApprovedMarketForwarder(
        uint256 _marketId,
        address _forwarder,
        address _account
    ) external view returns (bool);

    function approveMarketForwarder(
        uint256 _marketId,
        address _forwarder
    ) external;

    function setTrustedMarketForwarder(
        uint256 _marketId,
        address _forwarder
    ) external;

    function isTrustedMarketForwarder(
        uint256 _marketId,
        address _trustedMarketForwarder
    ) external view returns (bool);

    function marketRegistry() external view returns (IMarketRegistry);

    function collateralManager() external view returns (ICollateralManager);

    function protocolFee() external view returns (uint16);

    enum BidState {
        NONEXISTENT,
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID,
        LIQUIDATED,
        CLOSED
    }

    function getLoanSummary(
        uint256 _bidId
    )
        external
        view
        returns (
            address borrower,
            address lender,
            uint256 marketId,
            address principalTokenAddress,
            uint256 principalAmount,
            uint32 acceptedTimestamp,
            uint32 lastRepaidTimestamp,
            BidState bidState
        );

    function getLoanLendingToken(
        uint256 _bidId
    ) external view returns (address token_);

    function getLoanBorrower(
        uint256 _bidId
    ) external view returns (address borrower_);
}
