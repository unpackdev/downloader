// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./ILoanLiquidator.sol";

/// @title Interface for Loans.
/// @author Florida St
/// @notice Basic Loan
interface IBaseLoan {
    /// @notice Minimum improvement (in BPS) required for a strict improvement.
    /// @param principalAmount Minimum delta of principal amount.
    /// @param interest Minimum delta of interest.
    /// @param duration Minimum delta of duration.
    struct ImprovementMinimum {
        uint256 principalAmount;
        uint256 interest;
        uint256 duration;
    }

    /// @notice Arbitrary contract to validate offers implementing `IBaseOfferValidator`.
    /// @param validator Address of the validator contract.
    /// @param arguments Arguments to pass to the validator.
    struct OfferValidator {
        address validator;
        bytes arguments;
    }

    /// @notice Borrowers receive offers that are then validated.
    /// @dev Setting the nftCollateralTokenId to 0 triggers validation through `validators`.
    /// @param offerId Offer ID. Used for canceling/setting as executed.
    /// @param lender Lender of the offer.
    /// @param fee Origination fee.
    /// @param borrower Borrower of the offer. Can be set to 0 (any borrower).
    /// @param capacity Capacity of the offer.
    /// @param nftCollateralAddress Address of the NFT collateral.
    /// @param nftCollateralTokenId NFT collateral token ID.
    /// @param principalAddress Address of the principal.
    /// @param principalAmount Principal amount of the loan.
    /// @param aprBps APR in BPS.
    /// @param expirationTime Expiration time of the offer.
    /// @param duration Duration of the loan in seconds.
    /// @param validators Arbitrary contract to validate offers implementing `IBaseOfferValidator`.
    struct LoanOffer {
        uint256 offerId;
        address lender;
        uint256 fee;
        address borrower;
        uint256 capacity;
        address nftCollateralAddress;
        uint256 nftCollateralTokenId;
        address principalAddress;
        uint256 principalAmount;
        uint256 aprBps;
        uint256 expirationTime;
        uint256 duration;
        OfferValidator[] validators;
    }

    /// @notice Offer + necessary fields to execute a specific loan. This has a separate expirationTime to avoid
    /// someone holding an offer and executing much later, without the borrower's awareness.
    /// @param offer Loan offer. It can be executed potentially for multiple ids / amounts < principalAmount.
    /// @param tokenId NFT collateral token ID.
    /// @param amount The amount the borrower is willing to take (must be <= _loanOffer principalAmount)
    /// @param expirationTime Expiration time of the signed offer by the borrower.
    /// @param callbackData Data to pass to the callback.
    struct ExecutionData {
        LoanOffer offer;
        uint256 tokenId;
        uint256 amount;
        uint256 expirationTime;
        bytes callbackData;
    }

    /// @notice Recipient address and fraction of gains charged by the protocol.
    struct ProtocolFee {
        address recipient;
        uint256 fraction;
    }

    /// @notice Total number of loans issued by this contract.
    function getTotalLoansIssued() external view returns (uint256);

    /// @notice Cancel offer for `msg.sender`. Each lender has unique offerIds.
    /// @param _offerId Offer ID.
    function cancelOffer(uint256 _offerId) external;

    /// @notice Cancel multiple offers.
    /// @param _offerIds Offer IDs.
    function cancelOffers(uint256[] calldata _offerIds) external;

    /// @notice Cancell all offers with offerId < _minOfferId
    /// @param _minOfferId Minimum offer ID.
    function cancelAllOffers(uint256 _minOfferId) external;

    /// @notice Cancel renegotiation offer. Similar to offers.
    /// @param _renegotiationId Renegotiation offer ID.
    function cancelRenegotiationOffer(uint256 _renegotiationId) external;

    /// @notice Cancel multiple renegotiation offers.
    /// @param _renegotiationIds Renegotiation offer IDs.
    function cancelRenegotiationOffers(uint256[] calldata _renegotiationIds) external;

    /// @notice Cancell all renegotiation offers with renegotiationId < _minRenegotiationId
    /// @param _minRenegotiationId Minimum renegotiation offer ID.
    function cancelAllRenegotiationOffers(uint256 _minRenegotiationId) external;

    /// @return protocolFee The Protocol fee.
    function getProtocolFee() external view returns (ProtocolFee memory);

    /// @return pendingProtocolFee The pending protocol fee.
    function getPendingProtocolFee() external view returns (ProtocolFee memory);

    /// @return protocolFeeSetTime Time when the protocol fee was set to be changed.
    function getPendingProtocolFeeSetTime() external view returns (uint256);

    /// @notice Kicks off the process to update the protocol fee.
    /// @param _newProtocolFee New protocol fee.
    function updateProtocolFee(ProtocolFee calldata _newProtocolFee) external;

    /// @notice Set the protocol fee if enough notice has been given.
    function setProtocolFee() external;

    /// @return Liquidator contract address
    function getLiquidator() external returns (address);

    /// @notice Updates the liquidation contract.
    /// @param loanLiquidator New liquidation contract.
    function updateLiquidationContract(ILoanLiquidator loanLiquidator) external;

    /// @notice Updates the auction duration for liquidations.
    /// @param _newDuration New auction duration.
    function updateLiquidationAuctionDuration(uint48 _newDuration) external;

    /// @return auctionDuration Returns the auction's duration for liquidations.
    function getLiquidationAuctionDuration() external returns (uint48);
}
