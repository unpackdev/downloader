// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./SafeCast.sol";

import "./Structs.sol";
import "./User.sol";
import "./Collection.sol";
import "./Helper.sol";
import "./Errors.sol";
import "./Constants.sol";
import "./IFlooring.sol";
import "./SafeBox.sol";
import "./RollingBuckets.sol";

library AuctionLib {
    using SafeCast for uint256;
    using CollectionLib for CollectionState;
    using SafeBoxLib for SafeBox;
    using RollingBuckets for mapping(uint256 => uint256);
    using UserLib for UserFloorAccount;
    using UserLib for CollectionAccount;
    using Helper for CollectionState;

    event AuctionStartedV2(
        address indexed trigger,
        address indexed collection,
        uint64[] activityIds,
        uint256[] tokenIds,
        AuctionType typ,
        Fees fees,
        address settleToken,
        uint256 minimumBid,
        uint256 auctionEndTime,
        uint256 safeBoxExpiryTs,
        uint256 adminFee
    );

    event NewTopBidOnAuction(
        address indexed bidder,
        address indexed collection,
        uint64 activityId,
        uint256 tokenId,
        uint256 bidAmount,
        uint256 auctionEndTime,
        uint256 safeBoxExpiryTs
    );

    event AuctionEnded(
        address indexed winner,
        address indexed collection,
        uint64 activityId,
        uint256 tokenId,
        uint256 safeBoxKeyId,
        uint256 collectedFunds
    );

    function ownerInitAuctions(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        FeeConfig storage feeConf,
        address creditToken,
        address collectionId,
        uint256[] memory nftIds,
        uint256 maxExpiry,
        address token,
        uint256 minimumBid
    ) public {
        if (feeConf.safeboxFee.receipt == address(0)) revert Errors.TokenNotSupported();

        UserFloorAccount storage userAccount = userAccounts[msg.sender];
        uint256 adminFee = Constants.AUCTION_COST * nftIds.length;
        /// transfer fee to contract account
        userAccount.transferToken(userAccounts[address(this)], creditToken, adminFee, true);

        AuctionInfo memory auctionTemplate;
        auctionTemplate.endTime = uint96(block.timestamp + Constants.AUCTION_INITIAL_PERIODS);
        auctionTemplate.bidTokenAddress = token;
        auctionTemplate.minimumBid = minimumBid.toUint96();
        auctionTemplate.triggerAddress = msg.sender;
        auctionTemplate.lastBidAmount = 0;
        auctionTemplate.lastBidder = address(0);
        auctionTemplate.typ = AuctionType.Owned;
        auctionTemplate.fees = Fees({
            royalty: FeeRate({receipt: address(0), rateBips: 0}),
            protocol: FeeRate({receipt: feeConf.safeboxFee.receipt, rateBips: feeConf.safeboxFee.auctionOwned})
        });

        (uint64[] memory activityIds, uint192 newExpiryTs) =
            _ownerInitAuctions(collection, userAccount.getByKey(collectionId), nftIds, maxExpiry, auctionTemplate);

        emit AuctionStartedV2(
            msg.sender,
            collectionId,
            activityIds,
            nftIds,
            auctionTemplate.typ,
            auctionTemplate.fees,
            token,
            minimumBid,
            auctionTemplate.endTime,
            newExpiryTs,
            adminFee
        );
    }

    function _ownerInitAuctions(
        CollectionState storage collectionState,
        CollectionAccount storage userAccount,
        uint256[] memory nftIds,
        uint256 maxExpiry,
        AuctionInfo memory auctionTemplate
    ) private returns (uint64[] memory activityIds, uint32 newExpiryTs) {
        newExpiryTs = uint32(auctionTemplate.endTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS);

        uint256 firstIdx = Helper.counterStamp(newExpiryTs) - Helper.counterStamp(block.timestamp);

        uint256[] memory toUpdateBucket;
        /// if maxExpiryTs == 0, it means all nftIds in this batch being locked infinitely that we don't need to update countingBuckets
        if (maxExpiry > 0) {
            toUpdateBucket = collectionState.countingBuckets.batchGet(
                Helper.counterStamp(block.timestamp),
                Math.min(Helper.counterStamp(maxExpiry), collectionState.lastUpdatedBucket)
            );
        }

        activityIds = new uint64[](nftIds.length);
        for (uint256 i = 0; i < nftIds.length;) {
            if (collectionState.hasActiveActivities(nftIds[i])) revert Errors.NftHasActiveActivities();

            (SafeBox storage safeBox,) = collectionState.useSafeBoxAndKey(userAccount, nftIds[i]);

            if (safeBox.isInfiniteSafeBox()) {
                --collectionState.infiniteCnt;
            } else {
                uint256 oldExpiryTs = safeBox.expiryTs;
                if (oldExpiryTs < newExpiryTs) {
                    revert Errors.InvalidParam();
                }
                uint256 lastIdx = Helper.counterStamp(oldExpiryTs) - Helper.counterStamp(block.timestamp);
                if (firstIdx > lastIdx || lastIdx > toUpdateBucket.length) revert Errors.InvalidParam();
                for (uint256 k = firstIdx; k < lastIdx;) {
                    --toUpdateBucket[k];
                    unchecked {
                        ++k;
                    }
                }
            }

            safeBox.expiryTs = newExpiryTs;

            activityIds[i] = collectionState.generateNextActivityId();

            auctionTemplate.activityId = activityIds[i];
            collectionState.activeAuctions[nftIds[i]] = auctionTemplate;

            unchecked {
                ++i;
            }
        }
        if (toUpdateBucket.length > 0) {
            collectionState.countingBuckets.batchSet(Helper.counterStamp(block.timestamp), toUpdateBucket);
        }
    }

    function initAuctionOnExpiredSafeBoxes(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        FeeConfig storage feeConf,
        address creditToken,
        address collectionId,
        uint256[] memory nftIds,
        address bidToken,
        uint256 bidAmount
    ) public {
        if (feeConf.safeboxFee.receipt == address(0)) revert Errors.TokenNotSupported();
        {
            uint256 lockingRatio = Helper.calculateLockingRatio(collection, 0);
            (uint256 currentFee,) = Constants.getVaultFeeAtLR(lockingRatio);
            if (bidAmount < currentFee) revert Errors.AuctionInvalidBidAmount();
        }

        AuctionInfo memory auctionTemplate;
        auctionTemplate.endTime = uint96(block.timestamp + Constants.AUCTION_INITIAL_PERIODS);
        auctionTemplate.bidTokenAddress = bidToken;
        auctionTemplate.minimumBid = bidAmount.toUint96();
        auctionTemplate.triggerAddress = msg.sender;
        auctionTemplate.lastBidAmount = bidAmount.toUint96();
        auctionTemplate.lastBidder = msg.sender;
        auctionTemplate.typ = AuctionType.Expired;
        auctionTemplate.fees = Fees({
            royalty: FeeRate({receipt: address(0), rateBips: 0}),
            protocol: FeeRate({receipt: feeConf.safeboxFee.receipt, rateBips: feeConf.safeboxFee.auctionExpired})
        });

        (uint64[] memory activityIds, uint192 newExpiry) =
            _initAuctionOnExpiredSafeBoxes(collection, nftIds, auctionTemplate);

        uint256 adminFee = Constants.AUCTION_ON_EXPIRED_SAFEBOX_COST * nftIds.length;
        if (bidToken == creditToken) {
            userAccounts[msg.sender].transferToken(
                userAccounts[address(this)], bidToken, bidAmount * nftIds.length + adminFee, true
            );
        } else {
            userAccounts[msg.sender].transferToken(
                userAccounts[address(this)], bidToken, bidAmount * nftIds.length, false
            );
            if (adminFee > 0) {
                userAccounts[msg.sender].transferToken(userAccounts[address(this)], creditToken, adminFee, true);
            }
        }

        emit AuctionStartedV2(
            msg.sender,
            collectionId,
            activityIds,
            nftIds,
            auctionTemplate.typ,
            auctionTemplate.fees,
            bidToken,
            bidAmount,
            auctionTemplate.endTime,
            newExpiry,
            adminFee
        );
    }

    function _initAuctionOnExpiredSafeBoxes(
        CollectionState storage collectionState,
        uint256[] memory nftIds,
        AuctionInfo memory auctionTemplate
    ) private returns (uint64[] memory activityIds, uint32 newExpiry) {
        newExpiry = uint32(auctionTemplate.endTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS);

        activityIds = new uint64[](nftIds.length);
        for (uint256 idx; idx < nftIds.length;) {
            uint256 nftId = nftIds[idx];
            if (collectionState.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            SafeBox storage safeBox = collectionState.useSafeBox(nftId);
            if (!safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasNotExpire();
            if (Helper.isAuctionPeriodOver(safeBox)) revert Errors.SafeBoxAuctionWindowHasPassed();

            activityIds[idx] = collectionState.generateNextActivityId();
            auctionTemplate.activityId = activityIds[idx];
            collectionState.activeAuctions[nftId] = auctionTemplate;

            /// We keep the owner of safebox unchanged, and it will be used to distribute auction funds
            safeBox.expiryTs = newExpiry;
            safeBox.keyId = SafeBoxLib.SAFEBOX_KEY_NOTATION;

            unchecked {
                ++idx;
            }
        }

        Helper.applyDiffToCounters(
            collectionState, Helper.counterStamp(block.timestamp), Helper.counterStamp(newExpiry), int256(nftIds.length)
        );
    }

    function initAuctionOnVault(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        FeeConfig storage feeConf,
        address creditToken,
        address collectionId,
        uint256[] memory vaultIdx,
        address bidToken,
        uint96 bidAmount
    ) public {
        if (vaultIdx.length != 1) revert Errors.InvalidParam();
        if (feeConf.vaultFee.receipt == address(0)) revert Errors.TokenNotSupported();

        {
            /// check auction period and bid price
            uint256 lockingRatio = Helper.calculateLockingRatio(collection, 0);
            uint256 periodDuration = Constants.getVaultAuctionDurationAtLR(lockingRatio);
            if (block.timestamp - collection.lastVaultAuctionPeriodTs <= periodDuration) {
                revert Errors.PeriodQuotaExhausted();
            }

            (uint256 currentFee,) = Constants.getVaultFeeAtLR(lockingRatio);
            if (bidAmount < currentFee) revert Errors.AuctionInvalidBidAmount();
        }

        AuctionInfo memory auctionTemplate;
        auctionTemplate.endTime = uint96(block.timestamp + Constants.AUCTION_INITIAL_PERIODS);
        auctionTemplate.bidTokenAddress = bidToken;
        auctionTemplate.minimumBid = bidAmount;
        auctionTemplate.triggerAddress = msg.sender;
        auctionTemplate.lastBidAmount = bidAmount;
        auctionTemplate.lastBidder = msg.sender;
        auctionTemplate.typ = AuctionType.Vault;
        auctionTemplate.fees = Fees({
            royalty: FeeRate({receipt: feeConf.royalty.receipt, rateBips: feeConf.royalty.vault}),
            protocol: FeeRate({receipt: feeConf.vaultFee.receipt, rateBips: feeConf.vaultFee.vaultAuction})
        });

        SafeBox memory safeboxTemplate = SafeBox({
            keyId: SafeBoxLib.SAFEBOX_KEY_NOTATION,
            expiryTs: uint32(auctionTemplate.endTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS),
            owner: address(this)
        });

        uint64[] memory activityIds = new uint64[](vaultIdx.length);

        /// vaultIdx keeps asc order
        for (uint256 i = vaultIdx.length; i > 0;) {
            unchecked {
                --i;
            }

            if (vaultIdx[i] >= collection.freeTokenIds.length) revert Errors.InvalidParam();
            uint256 nftId = collection.freeTokenIds[vaultIdx[i]];

            collection.addSafeBox(nftId, safeboxTemplate);

            auctionTemplate.activityId = collection.generateNextActivityId();
            collection.activeAuctions[nftId] = auctionTemplate;
            activityIds[i] = auctionTemplate.activityId;

            collection.freeTokenIds[vaultIdx[i]] = collection.freeTokenIds[collection.freeTokenIds.length - 1];
            collection.freeTokenIds.pop();

            /// reuse the array
            vaultIdx[i] = nftId;
        }

        userAccounts[msg.sender].transferToken(
            userAccounts[address(this)],
            auctionTemplate.bidTokenAddress,
            bidAmount * vaultIdx.length,
            bidToken == creditToken
        );

        Helper.applyDiffToCounters(
            collection,
            Helper.counterStamp(block.timestamp),
            Helper.counterStamp(safeboxTemplate.expiryTs),
            int256(vaultIdx.length)
        );

        /// update auction timestamp
        collection.lastVaultAuctionPeriodTs = uint32(block.timestamp);

        emit AuctionStartedV2(
            msg.sender,
            collectionId,
            activityIds,
            vaultIdx,
            auctionTemplate.typ,
            auctionTemplate.fees,
            auctionTemplate.bidTokenAddress,
            bidAmount,
            auctionTemplate.endTime,
            safeboxTemplate.expiryTs,
            0
        );
    }

    struct BidParam {
        uint256 nftId;
        uint96 bidAmount;
        address bidder;
        uint256 extendDuration;
        uint256 minIncrPct;
    }

    function placeBidOnAuction(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address creditToken,
        address collectionId,
        uint256 nftId,
        uint256 bidAmount,
        uint256 bidOptionIdx
    ) public {
        uint256 prevBidAmount;
        address prevBidder;
        {
            Constants.AuctionBidOption memory bidOption = Constants.getBidOption(bidOptionIdx);
            userAccounts[msg.sender].ensureVipCredit(uint8(bidOption.vipLevel), creditToken);

            (prevBidAmount, prevBidder) = _placeBidOnAuction(
                collection,
                BidParam(
                    nftId, bidAmount.toUint96(), msg.sender, bidOption.extendDurationSecs, bidOption.minimumRaisePct
                )
            );
        }

        AuctionInfo memory auction = collection.activeAuctions[nftId];

        address bidToken = auction.bidTokenAddress;
        userAccounts[msg.sender].transferToken(
            userAccounts[address(this)], bidToken, bidAmount, bidToken == creditToken
        );

        if (prevBidAmount > 0) {
            /// refund previous bid
            /// contract account no need to check credit requirements
            userAccounts[address(this)].transferToken(userAccounts[prevBidder], bidToken, prevBidAmount, false);
        }

        SafeBox memory safebox = collection.safeBoxes[nftId];
        emit NewTopBidOnAuction(
            msg.sender, collectionId, auction.activityId, nftId, bidAmount, auction.endTime, safebox.expiryTs
        );
    }

    function _placeBidOnAuction(CollectionState storage collectionState, BidParam memory param)
        private
        returns (uint128 prevBidAmount, address prevBidder)
    {
        AuctionInfo storage auctionInfo = collectionState.activeAuctions[param.nftId];

        SafeBox storage safeBox = collectionState.useSafeBox(param.nftId);
        uint256 endTime = auctionInfo.endTime;
        {
            (prevBidAmount, prevBidder) = (auctionInfo.lastBidAmount, auctionInfo.lastBidder);
            // param check
            if (endTime == 0) revert Errors.AuctionNotExist();
            if (endTime <= block.timestamp) revert Errors.AuctionHasExpire();
            if (prevBidAmount >= param.bidAmount || auctionInfo.minimumBid > param.bidAmount) {
                revert Errors.AuctionBidIsNotHighEnough();
            }
            if (prevBidder == param.bidder) revert Errors.AuctionSelfBid();
            // owner starts auction, can not bid by himself
            if (auctionInfo.typ == AuctionType.Owned && param.bidder == safeBox.owner) revert Errors.AuctionSelfBid();

            if (prevBidAmount > 0 && !isValidNewBid(param.bidAmount, prevBidAmount, param.minIncrPct)) {
                revert Errors.AuctionInvalidBidAmount();
            }
        }

        /// Changing safebox key id which means the corresponding safebox key doesn't hold the safebox now
        safeBox.keyId = SafeBoxLib.SAFEBOX_KEY_NOTATION;

        uint256 newAuctionEndTime = block.timestamp + param.extendDuration;
        if (newAuctionEndTime > endTime) {
            uint256 newSafeBoxExpiryTs = newAuctionEndTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS;
            Helper.applyDiffToCounters(
                collectionState, Helper.counterStamp(safeBox.expiryTs), Helper.counterStamp(newSafeBoxExpiryTs), 1
            );

            safeBox.expiryTs = uint32(newSafeBoxExpiryTs);
            auctionInfo.endTime = uint96(newAuctionEndTime);
        }

        auctionInfo.lastBidAmount = param.bidAmount;
        auctionInfo.lastBidder = param.bidder;
    }

    function settleAuctions(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address collectionId,
        uint256[] memory nftIds
    ) public {
        for (uint256 i; i < nftIds.length;) {
            uint256 nftId = nftIds[i];
            SafeBox storage safebox = Helper.useSafeBox(collection, nftId);

            if (safebox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();

            AuctionInfo memory auctionInfo = collection.activeAuctions[nftId];
            if (auctionInfo.endTime == 0) revert Errors.AuctionNotExist();
            if (auctionInfo.endTime > block.timestamp) revert Errors.AuctionHasNotCompleted();
            /// noone bid on the aciton, can not be settled
            if (auctionInfo.lastBidder == address(0)) revert Errors.AuctionHasNotCompleted();

            distributeFunds(userAccounts, auctionInfo, safebox.owner);

            /// transfer safebox
            address winner = auctionInfo.lastBidder;
            SafeBoxKey memory key = SafeBoxKey({keyId: collection.generateNextKeyId(), lockingCredit: 0, vipLevel: 0});

            safebox.keyId = key.keyId;
            safebox.owner = winner;

            UserFloorAccount storage account = userAccounts[winner];
            CollectionAccount storage userCollectionAccount = account.getByKey(collectionId);
            userCollectionAccount.addSafeboxKey(nftId, key);

            delete collection.activeAuctions[nftId];

            emit AuctionEnded(winner, collectionId, auctionInfo.activityId, nftId, key.keyId, auctionInfo.lastBidAmount);

            unchecked {
                ++i;
            }
        }
    }

    function distributeFunds(
        mapping(address => UserFloorAccount) storage accounts,
        AuctionInfo memory auction,
        address owner
    ) private {
        /// contract account no need to check credit requirements
        address token = auction.bidTokenAddress;
        Fees memory fees = auction.fees;
        (uint256 priceWithoutFee, uint256 protocolFee, uint256 royalty) =
            Helper.computeFees(auction.lastBidAmount, fees);

        UserFloorAccount storage contractAccount = accounts[address(this)];

        if (royalty > 0) {
            contractAccount.transferToken(accounts[fees.royalty.receipt], token, royalty, false);
        }
        if (protocolFee > 0) {
            contractAccount.transferToken(accounts[fees.protocol.receipt], token, protocolFee, false);
        }
        if (priceWithoutFee > 0) {
            contractAccount.transferToken(accounts[owner], token, priceWithoutFee, false);
        }
    }

    function isValidNewBid(uint256 newBid, uint256 previousBid, uint256 minRaisePct) private pure returns (bool) {
        uint256 minIncrement = previousBid * minRaisePct / 100;
        if (minIncrement < 1) {
            minIncrement = 1;
        }

        if (newBid < previousBid + minIncrement) {
            return false;
        }
        // think: always thought this should be previousBid....
        uint256 newIncrementAmount = newBid / 100;
        if (newIncrementAmount < 1) {
            newIncrementAmount = 1;
        }
        return newBid % newIncrementAmount == 0;
    }
}
