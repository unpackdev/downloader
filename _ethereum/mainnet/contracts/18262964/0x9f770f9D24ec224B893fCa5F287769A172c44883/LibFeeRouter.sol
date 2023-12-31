// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppStorage.sol";
import "./LibObject.sol";
import "./LibConstants.sol";
import "./LibTokenizedVault.sol";
import "./CustomErrors.sol";

library LibFeeRouter {
    event FeePaid(bytes32 indexed fromId, bytes32 indexed toId, bytes32 tokenId, uint256 amount, uint256 feeType);

    event MakerBasisPointsUpdated(uint16 tradingCommissionMakerBP);
    event FeeScheduleAdded(bytes32 _entityId, uint256 _feeType, FeeSchedule feeSchedule);

    function _calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal view returns (CalculatedFees memory cf) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory commissionReceivers = s.simplePolicies[_policyId].commissionReceivers;
        uint256[] memory commissionBasisPoints = s.simplePolicies[_policyId].commissionBasisPoints;
        uint256 commissionsCount = commissionReceivers.length;

        bytes32 parentEntityId = LibObject._getParent(_policyId);
        FeeSchedule memory feeSchedule = _getFeeSchedule(parentEntityId, LibConstants.FEE_TYPE_PREMIUM);
        uint256 feeScheduleReceiversCount = feeSchedule.receiver.length;

        uint256 totalReceiverCount;
        totalReceiverCount += feeScheduleReceiversCount + commissionsCount;

        cf.feeAllocations = new FeeAllocation[](totalReceiverCount);

        uint256 fee;
        for (uint256 i; i < commissionsCount; ++i) {
            fee = (_premiumPaid * commissionBasisPoints[i]) / LibConstants.BP_FACTOR;

            cf.feeAllocations[i].to = commissionReceivers[i];
            cf.feeAllocations[i].basisPoints = commissionBasisPoints[i];
            cf.feeAllocations[i].fee = fee;

            cf.totalBP += commissionBasisPoints[i];
            cf.totalFees += fee;
        }

        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            fee = (_premiumPaid * feeSchedule.basisPoints[i]) / LibConstants.BP_FACTOR;

            cf.feeAllocations[commissionsCount + i].to = feeSchedule.receiver[i];
            cf.feeAllocations[commissionsCount + i].basisPoints = feeSchedule.basisPoints[i];
            cf.feeAllocations[commissionsCount + i].fee = fee;

            cf.totalBP += feeSchedule.basisPoints[i];
            cf.totalFees += fee;
        }
    }

    /// @dev The total bp for a policy premium fee schedule cannot exceed LibConstants.BP_FACTOR since the policy's additional fee receivers and fee schedule are each checked to be less than LibConstants.BP_FACTOR / 2 when they are being set.
    function _payPremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory commissionReceivers = s.simplePolicies[_policyId].commissionReceivers;
        uint256[] memory commissionBasisPoints = s.simplePolicies[_policyId].commissionBasisPoints;
        uint256 commissionsCount = commissionReceivers.length;

        bytes32 parentEntityId = LibObject._getParent(_policyId);

        bytes32 asset = s.simplePolicies[_policyId].asset;
        uint256 fee;
        for (uint256 i; i < commissionsCount; ++i) {
            fee = (_premiumPaid * commissionBasisPoints[i]) / LibConstants.BP_FACTOR;

            emit FeePaid(parentEntityId, commissionReceivers[i], asset, fee, LibConstants.FEE_TYPE_PREMIUM);
            LibTokenizedVault._internalTransfer(parentEntityId, commissionReceivers[i], asset, fee);
        }

        FeeSchedule memory feeSchedule = _getFeeSchedule(parentEntityId, LibConstants.FEE_TYPE_PREMIUM);

        uint256 feeScheduleReceiversCount = feeSchedule.receiver.length;
        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            fee = (_premiumPaid * feeSchedule.basisPoints[i]) / LibConstants.BP_FACTOR;

            if (fee > 0) {
                emit FeePaid(parentEntityId, feeSchedule.receiver[i], asset, fee, LibConstants.FEE_TYPE_PREMIUM);
                LibTokenizedVault._internalTransfer(parentEntityId, feeSchedule.receiver[i], asset, fee);
            }
        }
    }

    function _calculateTradingFees(
        bytes32 _buyerId,
        bytes32 _sellToken,
        bytes32 _buyToken,
        uint256 _buyAmount
    ) internal view returns (uint256 totalFees_, uint256 totalBP_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 offerId = s.bestOfferId[_buyToken][_sellToken];
        uint256 remainingBuyAmount = _buyAmount;
        uint256 offerCounter;

        while (remainingBuyAmount > 0) {
            // if no liquidity, apply default fees
            uint256 feeType = s.offers[offerId].sellAmount == 0 ? LibConstants.FEE_TYPE_INITIAL_SALE : s.offers[offerId].feeSchedule;
            FeeSchedule memory feeSchedule = _getFeeSchedule(_buyerId, feeType);

            uint256 amount = s.offers[offerId].sellAmount == 0 || remainingBuyAmount < s.offers[offerId].sellAmount ? remainingBuyAmount : s.offers[offerId].sellAmount;

            remainingBuyAmount -= amount;

            for (uint256 i; i < feeSchedule.basisPoints.length; i++) {
                totalFees_ += (amount * feeSchedule.basisPoints[i]) / LibConstants.BP_FACTOR;
                totalBP_ += feeSchedule.basisPoints[i];
            }

            if (s.tradingCommissionMakerBP > 0) {
                totalFees_ += (amount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
                totalBP_ += s.tradingCommissionMakerBP;
            }

            offerCounter++;
            offerId = s.offers[offerId].rankPrev;
        }
        totalBP_ = offerCounter > 0 ? totalBP_ / offerCounter : totalBP_; // normalize total BP
    }

    /// @dev The total bp for a marketplace fee schedule cannot exceed LibConstants.BP_FACTOR since the maker BP and fee schedules are each checked to be less than LibConstants.BP_FACTOR / 2 when they are being set.
    function _payTradingFees(
        uint256 _feeScheduleType,
        bytes32 _buyer,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount
    ) internal returns (uint256 totalFees_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Get the fee receivers for this _feeScheduleType
        FeeSchedule memory feeSchedule = _getFeeSchedule(_buyer, _feeScheduleType);

        uint256 fee;
        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
            totalFees_ += fee;

            emit FeePaid(_takerId, _makerId, _tokenId, fee, LibConstants.FEE_TYPE_TRADING);
            LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, fee);
        }

        uint256 feeScheduleReceiversCount = feeSchedule.receiver.length;
        for (uint256 i; i < feeScheduleReceiversCount; i++) {
            fee = (_buyAmount * feeSchedule.basisPoints[i]) / LibConstants.BP_FACTOR;

            if (fee > 0) {
                LibTokenizedVault._internalTransfer(_buyer, feeSchedule.receiver[i], _tokenId, fee);
                totalFees_ += fee;
                emit FeePaid(_buyer, feeSchedule.receiver[i], _tokenId, fee, LibConstants.FEE_TYPE_TRADING);
            }
        }
    }

    function _replaceMakerBP(uint16 tradingCommissionMakerBP) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (tradingCommissionMakerBP > LibConstants.BP_FACTOR / 2) {
            revert FeeBasisPointsExceedHalfMax(tradingCommissionMakerBP, LibConstants.BP_FACTOR / 2);
        }

        s.tradingCommissionMakerBP = tradingCommissionMakerBP;

        emit MakerBasisPointsUpdated(tradingCommissionMakerBP);
    }

    function _addFeeSchedule(
        bytes32 _entityId,
        uint256 _feeScheduleType,
        bytes32[] calldata _receiver,
        uint16[] calldata _basisPoints
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_receiver.length == _basisPoints.length, "receivers and basis points mismatch");

        // Remove the fee schedule for this _entityId/_feeScheduleType if it already exists
        delete s.feeSchedules[_entityId][_feeScheduleType];

        FeeSchedule memory feeSchedule = FeeSchedule({ receiver: _receiver, basisPoints: _basisPoints });

        // Check to see that the total basis points does not exceed LibConstants.BP_FACTOR / 2 basis points
        uint256 receiverCount = feeSchedule.receiver.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += feeSchedule.basisPoints[i];
        }
        if (totalBp > LibConstants.BP_FACTOR / 2) {
            revert FeeBasisPointsExceedHalfMax(totalBp, LibConstants.BP_FACTOR / 2);
        }

        s.feeSchedules[_entityId][_feeScheduleType] = feeSchedule;

        emit FeeScheduleAdded(_entityId, _feeScheduleType, feeSchedule);
    }

    /// @dev VERY IMPORTANT: always use this method to fetch the fee schedule because of fallback to default one!
    function _getFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) internal view returns (FeeSchedule memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        FeeSchedule memory feeSchedule = s.feeSchedules[_entityId][_feeScheduleType];

        if (feeSchedule.receiver.length == 0 || feeSchedule.receiver.length != feeSchedule.basisPoints.length) {
            // return default fee schedule
            feeSchedule = s.feeSchedules[LibConstants.DEFAULT_FEE_SCHEDULE][_feeScheduleType];
        }
        return feeSchedule;
    }

    function _removeFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) internal {
        require(_entityId != LibConstants.DEFAULT_FEE_SCHEDULE, "cannot remove default fees");
        AppStorage storage s = LibAppStorage.diamondStorage();
        delete s.feeSchedules[_entityId][_feeScheduleType];
    }

    function _getMakerBP() internal view returns (uint16) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tradingCommissionMakerBP;
    }
}
