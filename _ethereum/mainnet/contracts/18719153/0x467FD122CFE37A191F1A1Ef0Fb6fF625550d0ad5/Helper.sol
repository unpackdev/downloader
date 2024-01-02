// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Constants.sol";
import "./Errors.sol";
import "./SafeBox.sol";
import "./User.sol";
import "./Structs.sol";
import "./RollingBuckets.sol";

library Helper {
    using SafeBoxLib for SafeBox;
    using UserLib for CollectionAccount;
    using RollingBuckets for mapping(uint256 => uint256);

    function counterStamp(uint256 timestamp) internal pure returns (uint96) {
        unchecked {
            return uint96((timestamp + Constants.BUCKET_SPAN_1) / Constants.BUCKET_SPAN);
        }
    }

    function checkCollectionSafeboxQuota(
        CollectionAccount storage account,
        CollectionState storage collection,
        uint256 newLocked
    ) internal view {
        uint256 selfRatio = calculateSelfLockingRatio(
            account.keyCnt + newLocked, collection.activeSafeBoxCnt + collection.freeTokenIds.length + newLocked
        );
        if (selfRatio > Constants.USER_COLLECTION_LOCKED_BOUND_PCT) revert Errors.UserQuotaExhausted();
    }

    function checkAndUpdateUserSafeboxQuota(UserFloorAccount storage account, uint8 vipLevel, uint16 newLocked)
        internal
    {
        uint16 used = updateUserSafeboxQuota(account);
        uint16 totalQuota = Constants.getSafeboxPeriodQuota(vipLevel);

        uint16 nextUsed = used + newLocked;
        if (nextUsed > totalQuota) revert Errors.PeriodQuotaExhausted();

        account.safeboxQuotaUsed = nextUsed;

        checkSafeboxQuotaGlobal(account, vipLevel, newLocked);
    }

    function checkSafeboxQuotaGlobal(UserFloorAccount storage account, uint8 vipLevel, uint256 newLocked)
        internal
        view
    {
        uint256 totalQuota = Constants.getSafeboxUserQuota(vipLevel);
        if (totalQuota < newLocked) {
            revert Errors.UserQuotaExhausted();
        } else {
            unchecked {
                totalQuota -= newLocked;
            }
        }

        (, uint256[] memory keyCnts) = UserLib.getMinLevelAndVipKeyCounts(account.vipInfo);
        for (uint256 i; i < Constants.VIP_LEVEL_COUNT;) {
            if (totalQuota >= keyCnts[i]) {
                unchecked {
                    totalQuota -= keyCnts[i];
                }
            } else {
                revert Errors.UserQuotaExhausted();
            }
            unchecked {
                ++i;
            }
        }
    }

    function ensureProxyVipLevel(uint8 vipLevel, bool proxy) internal pure {
        if (proxy && vipLevel < Constants.PROXY_COLLECTION_VIP_THRESHOLD) {
            revert Errors.InvalidParam();
        }
    }

    function ensureMaxLocking(
        CollectionState storage collection,
        uint8 vipLevel,
        uint256 requireExpiryTs,
        uint256 requireLockCnt,
        bool extend
    ) internal view {
        /// vip level 0 can not use safebox utilities.
        if (vipLevel >= Constants.VIP_LEVEL_COUNT || vipLevel == 0) {
            revert Errors.InvalidParam();
        }

        uint256 lockingRatio = calculateLockingRatio(collection, requireLockCnt);
        uint256 restrictRatio;
        if (extend) {
            /// try to extend exist safebox
            /// only restrict infinity locking, normal safebox with expiry should be skipped
            restrictRatio = requireExpiryTs == 0 ? Constants.getLockingRatioForInfinite(vipLevel) : 100;
        } else {
            /// try to lock(create new safebox)
            /// restrict maximum locking ratio to use safebox
            restrictRatio = Constants.getLockingRatioForSafebox(vipLevel);
            if (requireExpiryTs == 0) {
                uint256 extraRatio = Constants.getLockingRatioForInfinite(vipLevel);
                if (restrictRatio > extraRatio) restrictRatio = extraRatio;
            }
        }

        if (lockingRatio > restrictRatio) revert Errors.InvalidParam();

        /// only check when it is not infinite lock
        if (requireExpiryTs > 0) {
            uint256 deltaBucket;
            unchecked {
                deltaBucket = counterStamp(requireExpiryTs) - counterStamp(block.timestamp);
            }
            if (deltaBucket == 0 || deltaBucket > Constants.getVipLockingBuckets(vipLevel)) {
                revert Errors.InvalidParam();
            }
        }
    }

    function useSafeBoxAndKey(CollectionState storage collection, CollectionAccount storage userAccount, uint256 nftId)
        internal
        view
        returns (SafeBox storage safeBox, SafeBoxKey storage key)
    {
        safeBox = collection.safeBoxes[nftId];
        if (safeBox.keyId == 0) revert Errors.SafeBoxNotExist();
        if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();

        key = userAccount.getByKey(nftId);
        if (!safeBox.isKeyMatchingSafeBox(key)) revert Errors.NoMatchingSafeBoxKey();
    }

    function useSafeBox(CollectionState storage collection, uint256 nftId)
        internal
        view
        returns (SafeBox storage safeBox)
    {
        safeBox = collection.safeBoxes[nftId];
        if (safeBox.keyId == 0) revert Errors.SafeBoxNotExist();
    }

    function generateNextKeyId(CollectionState storage collectionState) internal returns (uint64 nextKeyId) {
        nextKeyId = collectionState.nextKeyId;
        ++collectionState.nextKeyId;
    }

    function generateNextActivityId(CollectionState storage collection) internal returns (uint64 nextActivityId) {
        nextActivityId = collection.nextActivityId;
        ++collection.nextActivityId;
    }

    function isAuctionPeriodOver(SafeBox storage safeBox) internal view returns (bool) {
        return safeBox.expiryTs + Constants.FREE_AUCTION_PERIOD < block.timestamp;
    }

    function hasActiveActivities(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return hasActiveAuction(collection, nftId) || hasActiveRaffle(collection, nftId)
            || hasActivePrivateOffer(collection, nftId) || hasActiveListOffer(collection, nftId);
    }

    function hasActiveAuction(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return collection.activeAuctions[nftId].endTime >= block.timestamp;
    }

    function hasActiveRaffle(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return collection.activeRaffles[nftId].endTime >= block.timestamp;
    }

    function hasActivePrivateOffer(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return collection.activePrivateOffers[nftId].endTime >= block.timestamp;
    }

    function hasActiveListOffer(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        PrivateOffer storage offer = collection.activePrivateOffers[nftId];
        return offer.activityId > 0 && offer.buyer == address(0) && !useSafeBox(collection, nftId).isSafeBoxExpired();
    }

    function calculateActivityFee(uint256 settleAmount, uint256 feeRateBips)
        internal
        pure
        returns (uint256 afterFee, uint256 fee)
    {
        fee = settleAmount * feeRateBips / 10000;
        unchecked {
            afterFee = settleAmount - fee;
        }
    }

    function prepareBucketUpdate(CollectionState storage collection, uint256 startBucket, uint256 endBucket)
        internal
        view
        returns (uint256[] memory buckets)
    {
        uint256 validEnd = collection.lastUpdatedBucket;
        uint256 padding;
        if (endBucket < validEnd) {
            validEnd = endBucket;
        } else {
            unchecked {
                padding = endBucket - validEnd;
            }
        }

        if (startBucket < validEnd) {
            if (padding == 0) {
                buckets = collection.countingBuckets.batchGet(startBucket, validEnd);
            } else {
                uint256 validLen;
                unchecked {
                    validLen = validEnd - startBucket;
                }
                buckets = new uint256[](validLen + padding);
                uint256[] memory tmp = collection.countingBuckets.batchGet(startBucket, validEnd);
                for (uint256 i; i < validLen;) {
                    buckets[i] = tmp[i];
                    unchecked {
                        ++i;
                    }
                }
            }
        } else {
            buckets = new uint256[](endBucket - startBucket);
        }
    }

    function getActiveSafeBoxes(CollectionState storage collectionState, uint256 timestamp)
        internal
        view
        returns (uint256)
    {
        uint256 bucketStamp = counterStamp(timestamp);
        if (collectionState.lastUpdatedBucket < bucketStamp) {
            return 0;
        }
        return collectionState.countingBuckets.get(bucketStamp);
    }

    function calculateLockingRatio(CollectionState storage collection, uint256 newLocked)
        internal
        view
        returns (uint256)
    {
        uint256 freeAmount = collection.freeTokenIds.length;
        uint256 totalManaged = newLocked + collection.activeSafeBoxCnt + freeAmount;
        return calculateLockingRatioRaw(freeAmount, totalManaged);
    }

    function calculateLockingRatioRaw(uint256 freeAmount, uint256 totalManaged) internal pure returns (uint256) {
        if (totalManaged == 0) {
            return 0;
        } else {
            unchecked {
                return (100 - freeAmount * 100 / totalManaged);
            }
        }
    }

    function calculateSelfLockingRatio(uint256 selfLocked, uint256 collectionTatalManaged)
        internal
        pure
        returns (uint256)
    {
        if (collectionTatalManaged == 0) {
            return 0;
        } else {
            unchecked {
                return (selfLocked * 100 / collectionTatalManaged);
            }
        }
    }

    function updateUserSafeboxQuota(UserFloorAccount storage account) internal returns (uint16) {
        if (block.timestamp - account.lastQuotaPeriodTs <= Constants.USER_SAFEBOX_QUOTA_REFRESH_DURATION) {
            return account.safeboxQuotaUsed;
        } else {
            unchecked {
                account.lastQuotaPeriodTs = uint32(
                    block.timestamp / Constants.USER_SAFEBOX_QUOTA_REFRESH_DURATION
                        * Constants.USER_SAFEBOX_QUOTA_REFRESH_DURATION
                );
            }
            account.safeboxQuotaUsed = 0;
            return 0;
        }
    }

    function applyDiffToCounters(
        CollectionState storage collectionState,
        uint256 startBucket,
        uint256 endBucket,
        int256 diff
    ) internal {
        if (startBucket == endBucket) return;
        uint256[] memory buckets = Helper.prepareBucketUpdate(collectionState, startBucket, endBucket);
        unchecked {
            uint256 bucketLen = buckets.length;
            if (diff > 0) {
                uint256 tmp = uint256(diff);
                for (uint256 i; i < bucketLen; ++i) {
                    buckets[i] += tmp;
                }
            } else {
                uint256 tmp = uint256(-diff);
                for (uint256 i; i < bucketLen; ++i) {
                    buckets[i] -= tmp;
                }
            }
        }
        collectionState.countingBuckets.batchSet(startBucket, buckets);
        if (endBucket > collectionState.lastUpdatedBucket) {
            collectionState.lastUpdatedBucket = uint64(endBucket);
        }
    }

    function computeFees(uint256 price, Fees memory fees)
        internal
        pure
        returns (uint256 priceWithoutFee, uint256 protocolFee, uint256 royalty)
    {
        protocolFee = price * fees.protocol.rateBips / 10_000;
        royalty = price * fees.royalty.rateBips / 10_000;
        unchecked {
            priceWithoutFee = price - protocolFee - royalty;
        }
    }

    function checkAndUpdateVaultQuota(CollectionAccount storage account, int32 diff) internal {
        if (block.timestamp - account.lastVaultActiveTs > Constants.VAULT_QUOTA_RESET_PERIOD) {
            // exceeds the reset period
            if (diff < 0) revert Errors.UserQuotaExhausted();
            else account.vaultContQuota = uint32(diff);
        } else {
            int32 res = int32(account.vaultContQuota) + diff;
            if (res < 0) revert Errors.UserQuotaExhausted();
            else account.vaultContQuota = uint32(res);
        }

        if (diff > 0) {
            /// only refresh when increasing quota
            account.lastVaultActiveTs = uint32(block.timestamp);
        }
    }
}
