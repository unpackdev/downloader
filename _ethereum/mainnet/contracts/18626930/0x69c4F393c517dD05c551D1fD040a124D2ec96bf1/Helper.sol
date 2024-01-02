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

    function checkAndUpdateSafeboxPeriodQuota(UserFloorAccount storage account, uint8 vipLevel, uint16 newLocked)
        internal
    {
        uint16 used = updateUserSafeboxQuota(account);
        uint16 totalQuota = Constants.getSafeboxPeriodQuota(vipLevel);

        uint16 nextUsed = used + newLocked;
        if (nextUsed > totalQuota) revert Errors.PeriodQuotaExhausted();

        account.safeboxQuotaUsed = nextUsed;
    }

    function checkSafeboxUserQuota(UserFloorAccount storage account, uint8 vipLevel, uint256 newLocked) internal view {
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
                totalQuota -= keyCnts[i];
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
            || hasActivePrivateOffer(collection, nftId);
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

    function getTokenFeeRateBips(address creditToken, address floorToken, address settleToken)
        internal
        pure
        returns (uint256)
    {
        uint256 feeRateBips = Constants.COMMON_FEE_RATE_BIPS;
        if (settleToken == creditToken) {
            feeRateBips = Constants.CREDIT_FEE_RATE_BIPS;
        } else if (settleToken == floorToken) {
            feeRateBips = Constants.SPEC_FEE_RATE_BIPS;
        }

        return feeRateBips;
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

    function updateUserCreditWaiver(UserFloorAccount storage account) internal returns (uint96) {
        if (block.timestamp - account.lastWaiverPeriodTs <= Constants.USER_REDEMPTION_WAIVER_REFRESH_DURATION) {
            return account.creditWaiverUsed;
        } else {
            unchecked {
                account.lastWaiverPeriodTs = uint32(
                    block.timestamp / Constants.USER_REDEMPTION_WAIVER_REFRESH_DURATION
                        * Constants.USER_REDEMPTION_WAIVER_REFRESH_DURATION
                );
            }
            account.creditWaiverUsed = 0;
            return 0;
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
}
