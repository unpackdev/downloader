// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IMarketRegistry {
    enum PaymentType {
        EMI,
        Bullet
    }

    enum PaymentCycleType {
        Seconds,
        Monthly
    }

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        PaymentType _paymentType,
        PaymentCycleType _paymentCycleType,
        string calldata _uri
    ) external returns (uint256 marketId_);

    function getMarketplaceFee(
        uint256 _marketplaceId
    ) external view returns (uint16);
}
