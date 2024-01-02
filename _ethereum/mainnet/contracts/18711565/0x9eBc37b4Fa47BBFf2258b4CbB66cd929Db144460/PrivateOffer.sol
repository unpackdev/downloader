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
        uint256 adminFee,
        Fees fees
    );

    event PrivateOfferCanceled(
        address indexed operator, address indexed collection, uint64[] activityIds, uint256[] nftIds
    );

    event OfferMetaChanged(
        address indexed operator,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        uint96[] price,
        address settleToken,
        uint32 offerEndTime,
        uint32 safeboxExpiryTs
    );

    event PrivateOfferAccepted(
        address indexed buyer,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        uint256[] safeBoxKeyIds,
        uint32 safeboxExpiryTs
    );

    function ownerInitPrivateOffers(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        FeeConfig storage feeConf,
        address creditToken,
        IFlooring.PrivateOfferInitParam memory param
    ) public {
        if (param.receiver == msg.sender) revert Errors.InvalidParam();
        /// if receiver is none, means list and anyone can buy it
        if (param.receiver == address(0)) {
            return startListOffer(collection, userAccounts, feeConf, param);
        }

        UserFloorAccount storage userAccount = userAccounts[msg.sender];

        PrivateOffer memory offerTemplate = PrivateOffer({
            endTime: uint96(block.timestamp + Constants.PRIVATE_OFFER_DURATION),
            activityId: 0,
            token: param.token,
            price: param.price,
            owner: msg.sender,
            buyer: param.receiver,
            fees: Fees(FeeRate(address(0), 0), FeeRate(address(0), 0))
        });

        (uint64[] memory offerActivityIds, uint192 safeBoxExpiryTs) = _ownerInitPrivateOffers(
            collection, userAccount.getByKey(param.collection), param.nftIds, offerTemplate, param.maxExpiry
        );

        uint256 totalFeeCost = param.nftIds.length * Constants.PRIVATE_OFFER_COST;
        userAccount.transferToken(userAccounts[address(this)], creditToken, totalFeeCost, true);

        emit PrivateOfferStarted(
            msg.sender,
            param.receiver,
            param.collection,
            offerActivityIds,
            param.nftIds,
            param.token,
            param.price,
            offerTemplate.endTime,
            safeBoxExpiryTs,
            totalFeeCost,
            offerTemplate.fees
        );
    }

    function _ownerInitPrivateOffers(
        CollectionState storage collection,
        CollectionAccount storage userAccount,
        uint256[] memory nftIds,
        PrivateOffer memory offerTemplate,
        uint256 maxExpiry
    ) private returns (uint64[] memory offerActivityIds, uint32 safeBoxExpiryTs) {
        safeBoxExpiryTs = uint32(offerTemplate.endTime + Constants.PRIVATE_OFFER_COMPLETE_GRACE_DURATION);
        uint256 nowBucketCnt = Helper.counterStamp(block.timestamp);

        uint256[] memory toUpdateBucket;
        if (maxExpiry > 0) {
            toUpdateBucket = collection.countingBuckets.batchGet(
                nowBucketCnt, Math.min(collection.lastUpdatedBucket, Helper.counterStamp(maxExpiry))
            );
        }

        offerActivityIds = new uint64[](nftIds.length);
        uint256 firstIdx = Helper.counterStamp(safeBoxExpiryTs) - nowBucketCnt;
        for (uint256 i; i < nftIds.length;) {
            uint256 nftId = nftIds[i];
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
            offerTemplate.activityId = collection.generateNextActivityId();
            collection.activePrivateOffers[nftId] = offerTemplate;
            offerActivityIds[i] = offerTemplate.activityId;

            unchecked {
                ++i;
            }
        }
        if (toUpdateBucket.length > 0) {
            collection.countingBuckets.batchSet(nowBucketCnt, toUpdateBucket);
        }
    }

    function modifyOffers(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage accounts,
        address collectionId,
        uint256[] memory nftIds,
        IFlooring.OfferOpType opTy,
        bytes calldata data
    ) public {
        if (opTy == IFlooring.OfferOpType.Cancel || opTy == IFlooring.OfferOpType.Decline) {
            removePrivateOffers(collection, collectionId, nftIds);
        } else if (opTy == IFlooring.OfferOpType.ChangePrice) {
            IFlooring.ChangeOfferPriceData memory priceData = abi.decode(data, (IFlooring.ChangeOfferPriceData));
            modifyOfferPrice(collection, accounts[msg.sender], collectionId, nftIds, priceData.priceList);
        } else {
            revert Errors.InvalidParam();
        }
    }

    function removePrivateOffers(CollectionState storage collection, address collectionId, uint256[] memory nftIds)
        internal
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
        address creditToken,
        uint256[] memory nftIds,
        uint256 maxExpiry
    ) public {
        uint256[] memory safeBoxKeyIds = new uint256[](nftIds.length);
        uint64[] memory activityIds = new uint64[](nftIds.length);

        uint32 newExpiryTs = uint32(block.timestamp + Constants.PRIVATE_OFFER_COMPLETE_GRACE_DURATION);
        uint256[] memory toUpdateBucket;
        if (maxExpiry > 0) {
            toUpdateBucket = Helper.prepareBucketUpdate(
                collection,
                Helper.counterStamp(block.timestamp),
                Math.max(Helper.counterStamp(maxExpiry), Helper.counterStamp(newExpiryTs))
            );
        }

        for (uint256 i; i < nftIds.length;) {
            uint256 nftId = nftIds[i];
            if (!Helper.hasActiveListOffer(collection, nftId) && !Helper.hasActivePrivateOffer(collection, nftId)) {
                revert Errors.ActivityNotExist();
            }

            {
                PrivateOffer memory offer = collection.activePrivateOffers[nftId];
                if (offer.endTime > 0 && offer.endTime <= block.timestamp) revert Errors.ActivityHasExpired();
                if (offer.buyer != address(0) && offer.buyer != msg.sender) revert Errors.NoPrivilege();
                if (offer.owner == msg.sender) revert Errors.NoPrivilege();

                activityIds[i] = offer.activityId;

                distributeFunds(userAccounts, offer, creditToken);
            }

            SafeBoxKey memory newKey =
                SafeBoxKey({keyId: collection.generateNextKeyId(), vipLevel: 0, lockingCredit: 0});
            safeBoxKeyIds[i] = newKey.keyId;

            {
                /// transfer safebox key
                CollectionAccount storage buyerCollectionAccount = userAccounts[msg.sender].getByKey(collectionId);
                buyerCollectionAccount.addSafeboxKey(nftId, newKey);
            }

            /// update safebox
            SafeBox storage safeBox = collection.useSafeBox(nftId);
            /// this revert couldn't happen but just leaving it (we have checked offer'EndTime before)
            if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();
            safeBox.keyId = newKey.keyId;
            safeBox.owner = msg.sender;
            if (safeBox.isInfiniteSafeBox()) {
                --collection.infiniteCnt;
                /// infinite locked safebox should be shorten to the newExpiryTs
                safeBox.expiryTs = uint32(block.timestamp);
            }
            updateSafeboxBuckets(safeBox, toUpdateBucket, newExpiryTs);

            delete collection.activePrivateOffers[nftId];

            unchecked {
                ++i;
            }
        }

        if (toUpdateBucket.length > 0) {
            collection.countingBuckets.batchSet(Helper.counterStamp(block.timestamp), toUpdateBucket);
            uint96 newBucket = Helper.counterStamp(newExpiryTs);
            if (collection.lastUpdatedBucket < newBucket) {
                collection.lastUpdatedBucket = uint64(newBucket);
            }
        }

        emit PrivateOfferAccepted(msg.sender, collectionId, activityIds, nftIds, safeBoxKeyIds, newExpiryTs);
    }

    function modifyOfferPrice(
        CollectionState storage collection,
        UserFloorAccount storage ownerAccount,
        address collectionId,
        uint256[] memory nftIds,
        uint96[] memory newPriceList
    ) internal {
        if (nftIds.length != newPriceList.length) revert Errors.InvalidParam();

        CollectionAccount storage ownerCollection = ownerAccount.getByKey(collectionId);

        uint64[] memory activityIds = new uint64[](nftIds.length);
        for (uint256 i; i < nftIds.length;) {
            uint256 nftId = nftIds[i];
            PrivateOffer storage offer = collection.activePrivateOffers[nftId];
            if (offer.owner != msg.sender) revert Errors.NoPrivilege();
            if (offer.endTime > 0 && offer.endTime <= block.timestamp) revert Errors.ActivityHasExpired();

            /// dummy check ownership
            /// when offer.endTime is zero, we check the safebox expiry
            collection.useSafeBoxAndKey(ownerCollection, nftIds[i]);

            offer.price = newPriceList[i];
            activityIds[i] = offer.activityId;

            unchecked {
                ++i;
            }
        }

        /// time no change
        emit OfferMetaChanged(msg.sender, collectionId, activityIds, nftIds, newPriceList, address(0), 0, 0);
    }

    function startListOffer(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        FeeConfig storage feeConf,
        IFlooring.PrivateOfferInitParam memory param
    ) internal {
        if (feeConf.safeboxFee.receipt == address(0)) revert Errors.TokenNotSupported();

        PrivateOffer memory template = PrivateOffer({
            /// leave endTime empty as it is same as safebox expiry
            endTime: 0,
            activityId: 0,
            token: param.token,
            price: param.price,
            owner: msg.sender,
            buyer: address(0),
            fees: Fees({
                royalty: FeeRate({receipt: feeConf.royalty.receipt, rateBips: feeConf.royalty.marketlist}),
                protocol: FeeRate({receipt: feeConf.safeboxFee.receipt, rateBips: feeConf.safeboxFee.marketlist})
            })
        });
        CollectionAccount storage ownerCollection = userAccounts[msg.sender].getByKey(param.collection);

        uint64[] memory activityIds = new uint64[](param.nftIds.length);
        for (uint256 i; i < param.nftIds.length;) {
            uint256 nftId = param.nftIds[i];
            if (collection.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            /// dummy check
            collection.useSafeBoxAndKey(ownerCollection, nftId);

            template.activityId = Helper.generateNextActivityId(collection);
            collection.activePrivateOffers[nftId] = template;

            activityIds[i] = template.activityId;
            unchecked {
                ++i;
            }
        }

        emit PrivateOfferStarted(
            msg.sender,
            address(0), // buyer no restrictions
            param.collection,
            activityIds,
            param.nftIds,
            param.token,
            param.price,
            0, // same with safebox expiry each other
            0, // same with safebox expiry
            0, // no admin fee
            template.fees
        );
    }

    function updateSafeboxBuckets(SafeBox storage safebox, uint256[] memory buckets, uint32 newExpireTs) private {
        uint256 offset = Helper.counterStamp(block.timestamp);

        /// the safebox isn't expired, so that the bucket should be greater or equeal than `offset`
        uint256 safeboxExpiryBucketIdx = Helper.counterStamp(safebox.expiryTs) - offset;
        uint256 expectBucketIdx = Helper.counterStamp(newExpireTs) - offset;

        if (safeboxExpiryBucketIdx < expectBucketIdx) {
            /// expend the key,
            if (expectBucketIdx > buckets.length) revert Errors.InvalidParam();
            for (uint256 i = safeboxExpiryBucketIdx; i < expectBucketIdx;) {
                ++buckets[i];
                unchecked {
                    ++i;
                }
            }
        } else if (safeboxExpiryBucketIdx > expectBucketIdx) {
            /// shorten the key,
            if (safeboxExpiryBucketIdx > buckets.length) revert Errors.InvalidParam();
            for (uint256 i = expectBucketIdx; i < safeboxExpiryBucketIdx;) {
                --buckets[i];
                unchecked {
                    ++i;
                }
            }
        }
        safebox.expiryTs = newExpireTs;
    }

    function distributeFunds(
        mapping(address => UserFloorAccount) storage accounts,
        PrivateOffer memory offer,
        address creditToken
    ) private {
        if (offer.price > 0) {
            UserFloorAccount storage buyerAccount = accounts[msg.sender];
            address token = offer.token;
            (uint256 priceWithoutFee, uint256 protocolFee, uint256 royalty) =
                Helper.computeFees(offer.price, offer.fees);

            {
                /// calculate owner vip tier discounts
                uint8 ownerVipLevel = Constants.getVipLevel(accounts[offer.owner].tokenBalance(creditToken));
                uint256 protocolFeeAfterDiscount =
                    Constants.getListingProtocolFeeWithDiscount(protocolFee, ownerVipLevel);
                priceWithoutFee += (protocolFee - protocolFeeAfterDiscount);
                protocolFee = protocolFeeAfterDiscount;
            }

            buyerAccount.transferToken(accounts[offer.owner], token, priceWithoutFee, token == creditToken);
            buyerAccount.transferToken(
                accounts[offer.fees.protocol.receipt], offer.token, protocolFee, token == creditToken
            );
            buyerAccount.transferToken(accounts[offer.fees.royalty.receipt], offer.token, royalty, token == creditToken);
        }
    }
}
