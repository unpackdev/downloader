// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Math.sol";
import "./SafeCast.sol";
import "./IERC721.sol";

import "./RollingBuckets.sol";
import "./ERC721Transfer.sol";
import "./Array.sol";

import "./Errors.sol";
import "./Constants.sol";
import "./User.sol";
import "./Helper.sol";
import "./Structs.sol";
import "./SafeBox.sol";

import "./IFlooring.sol";

library CollectionLib {
    using SafeBoxLib for SafeBox;
    using SafeCast for uint256;
    using RollingBuckets for mapping(uint256 => uint256);
    using UserLib for CollectionAccount;
    using UserLib for UserFloorAccount;

    event LockNft(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        uint256 safeBoxExpiryTs,
        uint256 minMaintCredit,
        address proxyCollection
    );
    event ExtendKey(
        address indexed operator,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        uint256 safeBoxExpiryTs,
        uint256 minMaintCredit
    );
    event UnlockNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        address proxyCollection
    );
    event ExpiredNftToVault(address indexed operator, address indexed collection, uint256[] tokenIds);
    event FragmentNft(
        address indexed operator, address indexed onBehalfOf, address indexed collection, uint256[] tokenIds
    );
    event ClaimRandomNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        uint256 creditCost
    );

    function fragmentNFTs(
        CollectionState storage collectionState,
        UserFloorAccount storage account,
        address collection,
        uint256[] memory nftIds,
        address onBehalfOf
    ) public {
        uint256 nftLen = nftIds.length;

        /// tricky logic: if `onBehalfOf` is the contract, shaffle the correspounding amount of NFTs
        bool shuffle = onBehalfOf == address(this);

        uint256[] memory pickedTokenIds;
        if (shuffle) {
            uint256 vaultCnt = collectionState.freeTokenIds.length;
            /// no enough nft to shuffle
            if (nftLen > vaultCnt) revert Errors.ClaimableNftInsufficient();

            (pickedTokenIds,) = pickFromVault(collectionState, nftLen, 0, true);
        }

        /// after shuffling, supply new NFTs to vault
        uint32 contQuota;
        for (uint256 i; i < nftLen;) {
            collectionState.freeTokenIds.push(nftIds[i]);

            if (!shuffle) {
                contQuota += Constants.getVaultContQuotaAtLR(Helper.calculateLockingRatio(collectionState, 0));
            }

            unchecked {
                ++i;
            }
        }

        if (!shuffle) {
            /// if no shuffling, give back the Fragment Tokens
            collectionState.floorToken.mint(onBehalfOf, Constants.FLOOR_TOKEN_AMOUNT * nftLen);
            Helper.checkAndUpdateVaultQuota(account.getByKey(collection), int32(contQuota));
            ERC721Transfer.safeBatchTransferFrom(collection, msg.sender, address(this), nftIds);
        } else {
            /// if shuffling, transfer user's NFTs first to avoid repetition.
            ERC721Transfer.safeBatchTransferFrom(collection, msg.sender, address(this), nftIds);
            /// if shuffling, give back the picked NFTs
            ERC721Transfer.safeBatchTransferFrom(collection, address(this), msg.sender, pickedTokenIds);
            /// tracking the out NFTs
            emit ClaimRandomNft(msg.sender, msg.sender, collection, pickedTokenIds, 0);
        }

        emit FragmentNft(msg.sender, onBehalfOf, collection, nftIds);
    }

    struct LockInfo {
        bool isInfinite;
        uint256 currentBucket;
        uint256 newExpiryBucket;
        uint256 selfLocked;
        uint256 totalManaged;
        uint256 newRequireLockCredit;
        uint64 infiniteCnt;
    }

    function lockNfts(
        CollectionState storage collection,
        UserFloorAccount storage account,
        LockParam memory param,
        address onBehalfOf
    ) public returns (uint256 totalCreditCost) {
        if (onBehalfOf == address(this)) revert Errors.InvalidParam();
        /// proxy collection only enabled when infinity lock
        if (param.collection != param.proxyCollection && param.expiryTs != 0) revert Errors.InvalidParam();

        uint256 totalCredit = account.ensureVipCredit(param.vipLevel, param.creditToken);
        Helper.ensureMaxLocking(collection, param.vipLevel, param.expiryTs, param.nftIds.length, false);
        {
            uint8 maxVipLevel = Constants.getVipLevel(totalCredit);
            uint256 newLocked = param.nftIds.length;
            Helper.ensureProxyVipLevel(maxVipLevel, param.collection != param.proxyCollection);
            /// check period quota and global quota for the account
            Helper.checkAndUpdateUserSafeboxQuota(account, maxVipLevel, newLocked.toUint16());
            /// don't try to add the collection account
            Helper.checkCollectionSafeboxQuota(account.getByKey(param.collection), collection, newLocked);
        }

        /// cache value to avoid multi-reads
        uint256 minMaintCredit = account.minMaintCredit;
        uint256[] memory nftIds = param.nftIds;
        uint256[] memory newKeys;
        {
            CollectionAccount storage userCollectionAccount = account.getOrAddCollection(param.collection);

            (totalCreditCost, newKeys) =
                _lockNfts(collection, userCollectionAccount, nftIds, param.expiryTs, param.vipLevel);

            // compute max credit for locking cost
            uint96 totalLockingCredit = userCollectionAccount.totalLockingCredit;
            {
                uint256 creditBuffer;
                unchecked {
                    creditBuffer = totalCredit - totalLockingCredit;
                }
                if (totalCreditCost > creditBuffer || totalCreditCost > param.maxCreditCost) {
                    revert Errors.InsufficientCredit();
                }
            }

            totalLockingCredit += totalCreditCost.toUint96();
            userCollectionAccount.totalLockingCredit = totalLockingCredit;

            if (totalLockingCredit > minMaintCredit) {
                account.minMaintCredit = totalLockingCredit;
                minMaintCredit = totalLockingCredit;
            }
        }

        account.updateVipKeyCount(param.vipLevel, int256(nftIds.length));
        /// mint for `onBehalfOf`, transfer from msg.sender
        collection.floorToken.mint(onBehalfOf, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);
        ERC721Transfer.safeBatchTransferFrom(param.proxyCollection, msg.sender, address(this), nftIds);

        emit LockNft(
            msg.sender,
            onBehalfOf,
            param.collection,
            nftIds,
            newKeys,
            param.expiryTs,
            minMaintCredit,
            param.proxyCollection
        );
    }

    function _lockNfts(
        CollectionState storage collectionState,
        CollectionAccount storage account,
        uint256[] memory nftIds,
        uint256 expiryTs, // treat 0 as infinite lock.
        uint8 vipLevel
    ) private returns (uint256, uint256[] memory) {
        LockInfo memory info = LockInfo({
            isInfinite: expiryTs == 0,
            currentBucket: Helper.counterStamp(block.timestamp),
            newExpiryBucket: Helper.counterStamp(expiryTs),
            selfLocked: account.keyCnt,
            totalManaged: collectionState.activeSafeBoxCnt + collectionState.freeTokenIds.length,
            newRequireLockCredit: 0,
            infiniteCnt: collectionState.infiniteCnt
        });
        if (info.isInfinite) {
            /// if it is infinite lock, we need load all buckets to calculate the staking cost
            info.newExpiryBucket = Helper.counterStamp(block.timestamp + Constants.MAX_LOCKING_PERIOD);
        }

        uint256[] memory buckets = Helper.prepareBucketUpdate(collectionState, info.currentBucket, info.newExpiryBucket);
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length;) {
            uint256 lockedCredit = updateCountersAndGetSafeboxCredit(buckets, info, vipLevel);

            if (info.isInfinite) ++info.infiniteCnt;

            SafeBoxKey memory key = SafeBoxKey({
                keyId: Helper.generateNextKeyId(collectionState),
                lockingCredit: lockedCredit.toUint96(),
                vipLevel: vipLevel
            });

            account.addSafeboxKey(nftIds[idx], key);
            addSafeBox(
                collectionState, nftIds[idx], SafeBox({keyId: key.keyId, expiryTs: uint32(expiryTs), owner: msg.sender})
            );

            keys[idx] = SafeBoxLib.encodeSafeBoxKey(key);

            info.newRequireLockCredit += lockedCredit;
            unchecked {
                ++info.totalManaged;
                ++info.selfLocked;
                ++idx;
            }
        }

        if (info.isInfinite) {
            collectionState.infiniteCnt = info.infiniteCnt;
        } else {
            collectionState.countingBuckets.batchSet(info.currentBucket, buckets);
            if (info.newExpiryBucket > collectionState.lastUpdatedBucket) {
                collectionState.lastUpdatedBucket = uint64(info.newExpiryBucket);
            }
        }

        return (info.newRequireLockCredit, keys);
    }

    function unlockNfts(
        CollectionState storage collection,
        UserFloorAccount storage userAccount,
        address proxyCollection,
        address collectionId,
        uint256[] memory nftIds,
        uint256 maxExpiryTs,
        address receiver
    ) public {
        CollectionAccount storage userCollectionAccount = userAccount.getByKey(collectionId);
        SafeBoxKey[] memory releasedKeys = _unlockNfts(collection, maxExpiryTs, nftIds, userCollectionAccount);

        for (uint256 i = 0; i < releasedKeys.length;) {
            userAccount.updateVipKeyCount(releasedKeys[i].vipLevel, -1);
            unchecked {
                ++i;
            }
        }

        /// @dev if the receiver is the contract self, then unlock the safeboxes and dump the NFTs to the vault
        if (receiver == address(this)) {
            uint256 nftLen = nftIds.length;
            uint32 contQuota;
            for (uint256 i; i < nftLen;) {
                collection.freeTokenIds.push(nftIds[i]);
                contQuota += Constants.getVaultContQuotaAtLR(Helper.calculateLockingRatio(collection, 0));
                unchecked {
                    ++i;
                }
            }
            Helper.checkAndUpdateVaultQuota(userAccount.getByKey(collectionId), int32(contQuota));
            emit FragmentNft(msg.sender, msg.sender, collectionId, nftIds);
        } else {
            collection.floorToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);
            ERC721Transfer.safeBatchTransferFrom(proxyCollection, address(this), receiver, nftIds);
        }

        emit UnlockNft(msg.sender, receiver, collectionId, nftIds, proxyCollection);
    }

    function _unlockNfts(
        CollectionState storage collectionState,
        uint256 maxExpiryTs,
        uint256[] memory nftIds,
        CollectionAccount storage userCollectionAccount
    ) private returns (SafeBoxKey[] memory) {
        if (maxExpiryTs > 0 && maxExpiryTs < block.timestamp) revert Errors.SafeBoxHasExpire();
        SafeBoxKey[] memory expiredKeys = new SafeBoxKey[](nftIds.length);
        uint256 currentBucketTime = Helper.counterStamp(block.timestamp);
        uint256 creditToRelease = 0;
        uint256[] memory buckets;

        /// if maxExpiryTs == 0, it means all nftIds in this batch being locked infinitely that we don't need to update countingBuckets
        if (maxExpiryTs > 0) {
            uint256 maxExpiryBucketTime = Math.min(Helper.counterStamp(maxExpiryTs), collectionState.lastUpdatedBucket);
            buckets = collectionState.countingBuckets.batchGet(currentBucketTime, maxExpiryBucketTime);
        }

        for (uint256 i; i < nftIds.length;) {
            uint256 nftId = nftIds[i];

            if (Helper.hasActiveActivities(collectionState, nftId)) revert Errors.NftHasActiveActivities();

            (SafeBox storage safeBox, SafeBoxKey storage safeBoxKey) =
                Helper.useSafeBoxAndKey(collectionState, userCollectionAccount, nftId);

            creditToRelease += safeBoxKey.lockingCredit;
            if (safeBox.isInfiniteSafeBox()) {
                --collectionState.infiniteCnt;
            } else {
                uint256 limit = Helper.counterStamp(safeBox.expiryTs) - currentBucketTime;
                if (limit > buckets.length) revert();
                for (uint256 idx; idx < limit;) {
                    --buckets[idx];
                    unchecked {
                        ++idx;
                    }
                }
            }

            expiredKeys[i] = safeBoxKey;

            removeSafeBox(collectionState, nftId);
            userCollectionAccount.removeSafeboxKey(nftId);

            unchecked {
                ++i;
            }
        }

        userCollectionAccount.totalLockingCredit -= creditToRelease.toUint96();
        if (buckets.length > 0) {
            collectionState.countingBuckets.batchSet(currentBucketTime, buckets);
        }

        return expiredKeys;
    }

    function extendLockingForKeys(
        CollectionState storage collection,
        UserFloorAccount storage userAccount,
        LockParam memory param
    ) public returns (uint256 totalCreditCost) {
        uint8 newVipLevel = uint8(param.vipLevel);
        uint256 totalCredit = userAccount.ensureVipCredit(newVipLevel, param.creditToken);
        Helper.ensureMaxLocking(collection, newVipLevel, param.expiryTs, param.nftIds.length, true);

        uint256 minMaintCredit = userAccount.minMaintCredit;
        uint256[] memory safeBoxKeys;
        {
            CollectionAccount storage collectionAccount = userAccount.getOrAddCollection(param.collection);

            // extend lock duration
            int256[] memory vipLevelDiffs;
            (vipLevelDiffs, totalCreditCost, safeBoxKeys) =
                _extendLockingForKeys(collection, collectionAccount, param.nftIds, param.expiryTs, uint8(newVipLevel));

            // compute max credit for locking cost
            uint96 totalLockingCredit = collectionAccount.totalLockingCredit;
            {
                uint256 creditBuffer;
                unchecked {
                    creditBuffer = totalCredit - totalLockingCredit;
                }
                if (totalCreditCost > creditBuffer || totalCreditCost > param.maxCreditCost) {
                    revert Errors.InsufficientCredit();
                }
            }

            // update user vip key counts
            for (uint256 vipLevel = 0; vipLevel < vipLevelDiffs.length;) {
                userAccount.updateVipKeyCount(uint8(vipLevel), vipLevelDiffs[vipLevel]);
                unchecked {
                    ++vipLevel;
                }
            }

            totalLockingCredit += totalCreditCost.toUint96();
            collectionAccount.totalLockingCredit = totalLockingCredit;
            if (totalLockingCredit > minMaintCredit) {
                userAccount.minMaintCredit = totalLockingCredit;
                minMaintCredit = totalLockingCredit;
            }
        }

        emit ExtendKey(msg.sender, param.collection, param.nftIds, safeBoxKeys, param.expiryTs, minMaintCredit);
    }

    function _extendLockingForKeys(
        CollectionState storage collectionState,
        CollectionAccount storage userCollectionAccount,
        uint256[] memory nftIds,
        uint256 newExpiryTs, // expiryTs of 0 is infinite.
        uint8 newVipLevel
    ) private returns (int256[] memory, uint256, uint256[] memory) {
        LockInfo memory info = LockInfo({
            isInfinite: newExpiryTs == 0,
            currentBucket: Helper.counterStamp(block.timestamp),
            newExpiryBucket: Helper.counterStamp(newExpiryTs),
            selfLocked: userCollectionAccount.keyCnt,
            totalManaged: collectionState.activeSafeBoxCnt + collectionState.freeTokenIds.length,
            newRequireLockCredit: 0,
            infiniteCnt: collectionState.infiniteCnt
        });
        if (info.isInfinite) {
            info.newExpiryBucket = Helper.counterStamp(block.timestamp + Constants.MAX_LOCKING_PERIOD);
        }

        uint256[] memory buckets = Helper.prepareBucketUpdate(collectionState, info.currentBucket, info.newExpiryBucket);
        int256[] memory vipLevelDiffs = new int256[](Constants.VIP_LEVEL_COUNT);
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length;) {
            if (
                Helper.hasActiveActivities(collectionState, nftIds[idx])
                /// listing safebox can be extended
                && !Helper.hasActiveListOffer(collectionState, nftIds[idx])
            ) {
                revert Errors.NftHasActiveActivities();
            }

            (SafeBox storage safeBox, SafeBoxKey storage safeBoxKey) =
                Helper.useSafeBoxAndKey(collectionState, userCollectionAccount, nftIds[idx]);

            {
                uint256 extendOffset = Helper.counterStamp(safeBox.expiryTs) - info.currentBucket;
                unchecked {
                    for (uint256 i; i < extendOffset; ++i) {
                        if (buckets[i] == 0) revert Errors.InvalidParam();
                        --buckets[i];
                    }
                }
            }

            uint256 safeboxQuote = updateCountersAndGetSafeboxCredit(buckets, info, newVipLevel);

            if (safeboxQuote > safeBoxKey.lockingCredit) {
                info.newRequireLockCredit += (safeboxQuote - safeBoxKey.lockingCredit);
                safeBoxKey.lockingCredit = safeboxQuote.toUint96();
            }

            uint8 oldVipLevel = safeBoxKey.vipLevel;
            if (newVipLevel > oldVipLevel) {
                safeBoxKey.vipLevel = newVipLevel;
                --vipLevelDiffs[oldVipLevel];
                ++vipLevelDiffs[newVipLevel];
            }

            if (info.isInfinite) {
                safeBox.expiryTs = 0;
                ++info.infiniteCnt;
            } else {
                safeBox.expiryTs = uint32(newExpiryTs);
            }

            keys[idx] = SafeBoxLib.encodeSafeBoxKey(safeBoxKey);

            unchecked {
                ++idx;
            }
        }

        if (info.isInfinite) {
            collectionState.infiniteCnt = info.infiniteCnt;
        } else {
            collectionState.countingBuckets.batchSet(info.currentBucket, buckets);
            if (info.newExpiryBucket > collectionState.lastUpdatedBucket) {
                collectionState.lastUpdatedBucket = uint64(info.newExpiryBucket);
            }
        }
        return (vipLevelDiffs, info.newRequireLockCredit, keys);
    }

    function updateCountersAndGetSafeboxCredit(uint256[] memory counters, LockInfo memory lockInfo, uint8 vipLevel)
        private
        pure
        returns (uint256 result)
    {
        unchecked {
            uint256 infiniteCnt = lockInfo.infiniteCnt;
            uint256 totalManaged = lockInfo.totalManaged;

            uint256 counterOffsetEnd = (counters.length + 1) * 0x20;
            uint256 tmpCount;
            if (lockInfo.isInfinite) {
                for (uint256 i = 0x20; i < counterOffsetEnd; i += 0x20) {
                    assembly {
                        tmpCount := mload(add(counters, i))
                    }
                    result += Constants.getRequiredStakingForLockRatio(infiniteCnt + tmpCount, totalManaged);
                }
            } else {
                for (uint256 i = 0x20; i < counterOffsetEnd; i += 0x20) {
                    assembly {
                        tmpCount := mload(add(counters, i))
                    }
                    result += Constants.getRequiredStakingForLockRatio(infiniteCnt + tmpCount, totalManaged);
                    assembly {
                        /// increase counters[i]
                        mstore(add(counters, i), add(tmpCount, 1))
                    }
                }
                result = Constants.getVipRequiredStakingWithDiscount(result, vipLevel);
            }
            result = Constants.getRequiredStakingWithSelfRatio(
                result, Helper.calculateSelfLockingRatio(lockInfo.selfLocked, totalManaged)
            );
        }
    }

    function tidyExpiredNFTs(CollectionState storage collection, uint256[] memory nftIds, address collectionId)
        public
    {
        uint256 nftLen = nftIds.length;

        for (uint256 i; i < nftLen;) {
            uint256 nftId = nftIds[i];
            SafeBox storage safeBox = Helper.useSafeBox(collection, nftId);
            if (!safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasNotExpire();
            if (!Helper.isAuctionPeriodOver(safeBox)) revert Errors.AuctionHasNotCompleted();

            /// remove expired safebox, and dump it to vault
            removeSafeBox(collection, nftId);
            collection.freeTokenIds.push(nftId);

            unchecked {
                ++i;
            }
        }

        emit ExpiredNftToVault(msg.sender, collectionId, nftIds);
    }

    function claimRandomNFT(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        mapping(address => FeeConfig) storage feeConfs,
        address collectionId,
        uint256 claimCnt,
        uint256 maxCreditCost,
        address receiver
    ) public returns (uint256 totalCreditCost) {
        if (claimCnt == 0 || collection.freeTokenIds.length < claimCnt) revert Errors.ClaimableNftInsufficient();

        {
            uint256 freeAmount = collection.freeTokenIds.length;
            uint256 totalManaged = collection.activeSafeBoxCnt + freeAmount;
            /// when locking ratio greater than xx%, stop redemption
            if (
                Helper.calculateLockingRatioRaw(freeAmount - claimCnt, totalManaged - claimCnt)
                    > Constants.VAULT_REDEMPTION_MAX_LOKING_RATIO
            ) {
                revert Errors.ClaimableNftInsufficient();
            }
        }

        /// quota represented with 32 bits
        /// fragment token fee with 10^18 decimals
        bool useQuotaTx = (maxCreditCost >> 32) == 0;

        uint256[] memory selectedTokenIds;
        (selectedTokenIds, totalCreditCost) = pickFromVault(
            collection, claimCnt, feeConfs[address(collection.floorToken)].vaultFee.redemptionBase, useQuotaTx
        );

        if (totalCreditCost > maxCreditCost) {
            revert Errors.InsufficientCredit();
        }

        if (useQuotaTx) {
            UserFloorAccount storage userAccount = userAccounts[msg.sender];
            Helper.checkAndUpdateVaultQuota(userAccount.getByKey(collectionId), -int32(uint32(totalCreditCost)));
        } else {
            distributeRedemptionFunds(userAccounts, feeConfs, address(collection.floorToken), claimCnt, totalCreditCost);
        }

        collection.floorToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * selectedTokenIds.length);
        ERC721Transfer.safeBatchTransferFrom(collectionId, address(this), receiver, selectedTokenIds);

        emit ClaimRandomNft(msg.sender, receiver, collectionId, selectedTokenIds, totalCreditCost);
    }

    function pickFromVault(CollectionState storage collection, uint256 pickCnt, uint16 baseFeeRate, bool payWithQuota)
        private
        returns (uint256[] memory pickedTokenIds, uint256 totalCost)
    {
        pickedTokenIds = new uint256[](pickCnt);
        uint256 freeCnt = collection.freeTokenIds.length;
        uint256 totalManaged = collection.activeSafeBoxCnt + freeCnt;
        while (pickCnt > 0) {
            uint256 lockingRatio = Helper.calculateLockingRatioRaw(freeCnt, totalManaged);
            if (payWithQuota) {
                totalCost += Constants.getVaultQuotaFeeAtLR(lockingRatio);
            } else {
                totalCost += Constants.getVaultRedemptionFee(lockingRatio, baseFeeRate);
            }

            /// just compute a deterministic random number
            uint256 chosenNftIdx =
                uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, totalManaged))) % freeCnt;

            unchecked {
                --pickCnt;
                --totalManaged;
                --freeCnt;
            }

            pickedTokenIds[pickCnt] = collection.freeTokenIds[chosenNftIdx];

            collection.freeTokenIds[chosenNftIdx] = collection.freeTokenIds[freeCnt];
            collection.freeTokenIds.pop();
        }
    }

    function distributeRedemptionFunds(
        mapping(address => UserFloorAccount) storage accounts,
        mapping(address => FeeConfig) storage feeConfs,
        address token,
        uint256 redeemCnt,
        uint256 totalPrice
    ) private {
        address protocolReceipt = feeConfs[token].vaultFee.receipt;
        address royaltyReceipt = feeConfs[token].royalty.receipt;

        /// a bit difference, for vault redemption with fee, we treat royaltyRate as bips of the Fragment Token amount of 1 NFT
        /// so the dust will be the incoming to the protocol
        uint256 royaltyRate = feeConfs[token].royalty.vault;
        uint256 royalty = redeemCnt * (Constants.FLOOR_TOKEN_AMOUNT / 10000 * royaltyRate);
        if (totalPrice < royalty) {
            royalty = totalPrice;
        }

        UserFloorAccount storage userAccount = accounts[msg.sender];
        userAccount.transferToken(accounts[protocolReceipt], token, totalPrice - royalty, false);
        userAccount.transferToken(accounts[royaltyReceipt], token, royalty, false);
    }

    function getLockingBuckets(CollectionState storage collection, uint256 startTimestamp, uint256 endTimestamp)
        public
        view
        returns (uint256[] memory)
    {
        return Helper.prepareBucketUpdate(
            collection,
            Helper.counterStamp(startTimestamp),
            Math.min(collection.lastUpdatedBucket, Helper.counterStamp(endTimestamp))
        );
    }

    function addSafeBox(CollectionState storage collectionState, uint256 nftId, SafeBox memory safebox) internal {
        if (collectionState.safeBoxes[nftId].keyId > 0) revert Errors.SafeBoxAlreadyExist();
        collectionState.safeBoxes[nftId] = safebox;
        ++collectionState.activeSafeBoxCnt;
    }

    function removeSafeBox(CollectionState storage collectionState, uint256 nftId) internal {
        delete collectionState.safeBoxes[nftId];
        --collectionState.activeSafeBoxCnt;
    }
}
