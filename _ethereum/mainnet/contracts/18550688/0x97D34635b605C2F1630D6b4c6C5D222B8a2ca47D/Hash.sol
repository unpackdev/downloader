// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IMultiSourceLoan.sol";
import "./IBaseLoan.sol";
import "./IAuctionLoanLiquidator.sol";

library Hash {
    // keccak256("OfferValidator(address validator,bytes arguments)")
    bytes32 private constant _VALIDATOR_HASH = 0x4def3e04bd42194484d5f8a5b268ec0df03b9d9d0402606fe3100023c5d79ac4;

    // keccak256("LoanOffer(uint256 offerId,address lender,uint256 fee,address borrower,uint256 capacity,address nftCollateralAddress,uint256 nftCollateralTokenId,address principalAddress,uint256 principalAmount,uint256 aprBps,uint256 expirationTime,uint256 duration,OfferValidator[] validators)OfferValidator(address validator,bytes arguments)")
    bytes32 private constant _LOAN_OFFER_HASH = 0x891e530ed2768a9decac48f4b7beec447f755ce23feeeeb952e429145b44ba91;

    /// keccak256("ExecutionData(LoanOffer offer,uint256 tokenId,uint256 amount,uint256 expirationTime,bytes callbackData)LoanOffer(uint256 offerId,address lender,uint256 fee,address borrower,uint256 capacity,address nftCollateralAddress,uint256 nftCollateralTokenId,address principalAddress,uint256 principalAmount,uint256 aprBps,uint256 expirationTime,uint256 duration,OfferValidator[] validators)OfferValidator(address validator,bytes arguments)")
    bytes32 private constant _EXECUTION_DATA_HASH = 0x7e90717662b6dd110797922ef6d6701d92bfd4164783966933e092ea21a74c5a;

    /// keccak256("SignableRepaymentData(uint256 loanId,bytes callbackData,bool shouldDelegate)")
    bytes32 private constant _SIGNABLE_REPAYMENT_DATA_HASH =
        0x41277b3c1cbe08ea7bbdd10a13f24dc956f3936bf46526f904c73697d9958e0c;

    // keccak256("Loan(address borrower,uint256 nftCollateralTokenId,address nftCollateralAddress,address principalAddress,uint256 principalAmount,uint256 startTime,uint256 duration,Source[] source)Source(uint256 loanId,address lender,uint256 principalAmount,uint256 accruedInterest,uint256 startTime,uint256 aprBps)")
    bytes32 private constant _MULTI_SOURCE_LOAN_HASH =
        0x35f73c5cb07b3fa605378d4f576769166fed212ec3813ac1f1d73ef1c537eb0e;

    // keccak256("Source(uint256 loanId,address lender,uint256 principalAmount,uint256 accruedInterest,uint256 startTime,uint256 aprBps)")
    bytes32 private constant _SOURCE_HASH = 0x8ca047c2f10359bf4a27bd2c623674be3801153b6b2646ba08593dc96ad7bb44;

    /// keccak256("RenegotiationOffer(uint256 renegotiationId,uint256 loanId,address lender,uint256 fee,uint256[] targetPrincipal,uint256 principalAmount,uint256 aprBps,uint256 expirationTime,uint256 duration)")
    bytes32 private constant _MULTI_RENEGOTIATION_OFFER_HASH =
        0xdb613ea3383336cd787d929ccfc21ab7cd87bf1d588780c80ce5f970dd79c348;

    /// keccak256("Auction(address loanAddress,uint256 loanId,uint256 highestBid,uint256 triggerFee,address highestBidder,uint96 duration,address asset,uint96 startTime,address originator,uint96 lastBidTime)")
    bytes32 private constant _AUCTION_HASH = 0xd1912299766a3d3ca1ad2e2135d884e08d798009860146382d22f8c389905b34;

    function hash(IBaseLoan.LoanOffer memory _loanOffer) internal pure returns (bytes32) {
        bytes memory encodedValidators;
        for (uint256 i = 0; i < _loanOffer.validators.length;) {
            encodedValidators = abi.encodePacked(encodedValidators, _hashValidator(_loanOffer.validators[i]));

            unchecked {
                ++i;
            }
        }
        return keccak256(
            abi.encode(
                _LOAN_OFFER_HASH,
                _loanOffer.offerId,
                _loanOffer.lender,
                _loanOffer.fee,
                _loanOffer.borrower,
                _loanOffer.capacity,
                _loanOffer.nftCollateralAddress,
                _loanOffer.nftCollateralTokenId,
                _loanOffer.principalAddress,
                _loanOffer.principalAmount,
                _loanOffer.aprBps,
                _loanOffer.expirationTime,
                _loanOffer.duration,
                keccak256(encodedValidators)
            )
        );
    }

    function hash(IBaseLoan.ExecutionData memory _executionData) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _EXECUTION_DATA_HASH,
                hash(_executionData.offer),
                _executionData.tokenId,
                _executionData.amount,
                _executionData.expirationTime,
                keccak256(_executionData.callbackData)
            )
        );
    }

    function hash(IMultiSourceLoan.SignableRepaymentData memory _repaymentData) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _SIGNABLE_REPAYMENT_DATA_HASH,
                _repaymentData.loanId,
                keccak256(_repaymentData.callbackData),
                _repaymentData.shouldDelegate
            )
        );
    }

    function hash(IMultiSourceLoan.Loan memory _loan) internal pure returns (bytes32) {
        bytes memory sourceHashes;
        for (uint256 i = 0; i < _loan.source.length;) {
            sourceHashes = abi.encodePacked(sourceHashes, _hashSource(_loan.source[i]));
            unchecked {
                ++i;
            }
        }
        return keccak256(
            abi.encode(
                _MULTI_SOURCE_LOAN_HASH,
                _loan.borrower,
                _loan.nftCollateralTokenId,
                _loan.nftCollateralAddress,
                _loan.principalAddress,
                _loan.principalAmount,
                _loan.startTime,
                _loan.duration,
                keccak256(sourceHashes)
            )
        );
    }

    function hash(IMultiSourceLoan.RenegotiationOffer memory _refinanceOffer) internal pure returns (bytes32) {
        bytes memory encodedPrincipals;
        for (uint256 i = 0; i < _refinanceOffer.targetPrincipal.length;) {
            encodedPrincipals = abi.encodePacked(encodedPrincipals, _refinanceOffer.targetPrincipal[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(
            abi.encode(
                _MULTI_RENEGOTIATION_OFFER_HASH,
                _refinanceOffer.renegotiationId,
                _refinanceOffer.loanId,
                _refinanceOffer.lender,
                _refinanceOffer.fee,
                keccak256(encodedPrincipals),
                _refinanceOffer.principalAmount,
                _refinanceOffer.aprBps,
                _refinanceOffer.expirationTime,
                _refinanceOffer.duration
            )
        );
    }

    function hash(IAuctionLoanLiquidator.Auction memory _auction) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _AUCTION_HASH,
                _auction.loanAddress,
                _auction.loanId,
                _auction.highestBid,
                _auction.triggerFee,
                _auction.highestBidder,
                _auction.duration,
                _auction.asset,
                _auction.startTime,
                _auction.originator,
                _auction.lastBidTime
            )
        );
    }

    function _hashSource(IMultiSourceLoan.Source memory _source) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _SOURCE_HASH,
                _source.lender,
                _source.principalAmount,
                _source.accruedInterest,
                _source.startTime,
                _source.aprBps
            )
        );
    }

    function _hashValidator(IBaseLoan.OfferValidator memory _validator) private pure returns (bytes32) {
        return keccak256(abi.encode(_VALIDATOR_HASH, _validator.validator, keccak256(_validator.arguments)));
    }
}
