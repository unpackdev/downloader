// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Math.sol";

import "./Errors.sol";
import "./IFlooring.sol";
import "./RollingBuckets.sol";
import "./Structs.sol";
import "./SafeBox.sol";
import "./User.sol";
import "./Helper.sol";

library PrivateOfferLib {
    using SafeBoxLib for SafeBox;
    using RollingBuckets for mapping(uint256 => uint256);
    using UserLib for UserFloorAccount;
    using UserLib for CollectionAccount;
    using Helper for CollectionState;

    // todo: event should be moved to Interface as far as Solidity 0.8.22 ready.
    // https://github.com/ethereum/solidity/pull/14274
    // https://github.com/ethereum/solidity/issues/14430
    event PrivateOfferStarted(
        address indexed seller,
        address indexed buyer,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        address settleToken,
        uint96 price,
        uint256 offerEndTime,
        uint256 safeBoxExpiryTs,
        uint256 adminFee
    );

    event PrivateOfferCanceled(
        address indexed operator, address indexed collection, uint64[] activityIds, uint256[] nftIds
    );

    event PrivateOfferAccepted(
        address indexed buyer,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        uint256[] safeBoxKeyIds
    );

    struct PrivateOfferSettlement {
        SafeBoxKey safeBoxKey;
        uint256 nftId;
        address token;
        uint128 collectedFund;
        address seller;
        address buyer;
    }

    function ownerInitPrivateOffers(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address creditToken,
        IFlooring.PrivateOfferInitParam memory param
    ) public {
        UserFloorAccount storage userAccount = userAccounts[msg.sender];
        uint256 totalFeeCost = param.nftIds.length * Constants.PRIVATE_OFFER_COST;
        userAccount.transferToken(userAccounts[address(this)], creditToken, totalFeeCost, true);

        (uint64[] memory offerActivityIds, uint96 offerEndTime, uint192 safeBoxExpiryTs) =
            _ownerInitPrivateOffers(collection, userAccount.getByKey(param.collection), param);

        emit PrivateOfferStarted(
            msg.sender,
            param.receiver,
            param.collection,
            offerActivityIds,
            param.nftIds,
            param.token,
            param.price,
            offerEndTime,
            safeBoxExpiryTs,
            totalFeeCost
        );
    }

    function _ownerInitPrivateOffers(
        CollectionState storage collection,
        CollectionAccount storage userAccount,
        IFlooring.PrivateOfferInitParam memory param
    ) private returns (uint64[] memory offerActivityIds, uint96 offerEndTime, uint32 safeBoxExpiryTs) {
        if (param.receiver == msg.sender) {
            revert Errors.InvalidParam();
        }

        offerEndTime = uint96(block.timestamp + Constants.PRIVATE_OFFER_DURATION);
        safeBoxExpiryTs = uint32(offerEndTime + Constants.PRIVATE_OFFER_COMPLETE_GRACE_DURATION);
        uint256 nowBucketCnt = Helper.counterStamp(block.timestamp);

        uint256[] memory toUpdateBucket;
        if (param.maxExpiry > 0) {
            toUpdateBucket = collection.countingBuckets.batchGet(
                nowBucketCnt, Math.min(collection.lastUpdatedBucket, Helper.counterStamp(param.maxExpiry))
            );
        }

        uint256 nftLen = param.nftIds.length;
        offerActivityIds = new uint64[](nftLen);
        uint256 firstIdx = Helper.counterStamp(safeBoxExpiryTs) - nowBucketCnt;
        for (uint256 i; i < nftLen;) {
            uint256 nftId = param.nftIds[i];
            if (collection.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            (SafeBox storage safeBox,) = collection.useSafeBoxAndKey(userAccount, nftId);

            if (safeBox.isInfiniteSafeBox()) {
                --collection.infiniteCnt;
            } else {
                uint256 oldExpiryTs = safeBox.expiryTs;
                if (oldExpiryTs < safeBoxExpiryTs) {
                    revert Errors.InvalidParam();
                }
                uint256 lastIdx = Helper.counterStamp(oldExpiryTs) - nowBucketCnt;
                if (firstIdx > lastIdx || lastIdx > toUpdateBucket.length) revert Errors.InvalidParam();
                for (uint256 k = firstIdx; k < lastIdx;) {
                    --toUpdateBucket[k];
                    unchecked {
                        ++k;
                    }
                }
            }

            safeBox.expiryTs = safeBoxExpiryTs;
            offerActivityIds[i] = collection.generateNextActivityId();
            collection.activePrivateOffers[nftId] = PrivateOffer({
                endTime: offerEndTime,
                owner: msg.sender,
                buyer: param.receiver,
                token: param.token,
                price: param.price,
                activityId: offerActivityIds[i]
            });

            unchecked {
                ++i;
            }
        }
        if (toUpdateBucket.length > 0) {
            collection.countingBuckets.batchSet(nowBucketCnt, toUpdateBucket);
        }
    }

    function removePrivateOffers(CollectionState storage collection, address collectionId, uint256[] memory nftIds)
        public
    {
        uint64[] memory offerActivityIds = new uint64[](nftIds.length);
        for (uint256 i; i < nftIds.length;) {
            uint256 nftId = nftIds[i];
            PrivateOffer storage offer = collection.activePrivateOffers[nftId];
            if (offer.owner != msg.sender && offer.buyer != msg.sender) revert Errors.NoPrivilege();

            offerActivityIds[i] = offer.activityId;
            delete collection.activePrivateOffers[nftId];

            unchecked {
                ++i;
            }
        }

        emit PrivateOfferCanceled(msg.sender, collectionId, offerActivityIds, nftIds);
    }

    function buyerAcceptPrivateOffers(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address collectionId,
        uint256[] memory nftIds,
        address creditToken
    ) public {
        (PrivateOfferSettlement[] memory settlements, uint64[] memory activityIds) =
            _buyerAcceptPrivateOffers(collection, nftIds);

        uint256[] memory safeBoxKeyIds = new uint256[](settlements.length);
        for (uint256 i; i < settlements.length;) {
            PrivateOfferSettlement memory settlement = settlements[i];

            UserFloorAccount storage buyerAccount = userAccounts[settlement.buyer];
            CollectionAccount storage buyerCollectionAccount = buyerAccount.getByKey(collectionId);

            buyerCollectionAccount.addSafeboxKey(settlement.nftId, settlement.safeBoxKey);

            if (settlement.collectedFund > 0) {
                UserFloorAccount storage sellerAccount = userAccounts[settlement.seller];
                buyerAccount.transferToken(
                    sellerAccount, settlement.token, settlement.collectedFund, settlement.token == creditToken
                );
            }

            safeBoxKeyIds[i] = settlement.safeBoxKey.keyId;

            unchecked {
                ++i;
            }
        }
        emit PrivateOfferAccepted(msg.sender, collectionId, activityIds, nftIds, safeBoxKeyIds);
    }

    function _buyerAcceptPrivateOffers(CollectionState storage collection, uint256[] memory nftIds)
        private
        returns (PrivateOfferSettlement[] memory settlements, uint64[] memory offerActivityIds)
    {
        uint256 nftLen = nftIds.length;
        settlements = new PrivateOfferSettlement[](nftLen);
        offerActivityIds = new uint64[](nftLen);
        for (uint256 i; i < nftLen;) {
            uint256 nftId = nftIds[i];
            PrivateOffer storage offer = collection.activePrivateOffers[nftId];
            if (offer.endTime <= block.timestamp) revert Errors.ActivityHasExpired();
            if (offer.buyer != msg.sender) revert Errors.NoPrivilege();

            SafeBox storage safeBox = collection.useSafeBox(nftId);
            if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();

            SafeBoxKey memory newKey =
                SafeBoxKey({keyId: collection.generateNextKeyId(), vipLevel: 0, lockingCredit: 0});
            safeBox.keyId = newKey.keyId;
            safeBox.owner = msg.sender;

            settlements[i] = PrivateOfferSettlement({
                safeBoxKey: newKey,
                nftId: nftId,
                seller: offer.owner,
                buyer: msg.sender,
                token: offer.token,
                collectedFund: offer.price
            });
            offerActivityIds[i] = offer.activityId;

            delete collection.activePrivateOffers[nftId];

            unchecked {
                ++i;
            }
        }
    }
}
