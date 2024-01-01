// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Structs.sol";

interface IFlooringEvent {
    event NewCollectionSupported(address indexed collection, address indexed floorToken);
    event UpdateTokenSupported(address indexed token, bool addOrRemove);
    event ProxyCollectionChanged(address indexed proxyCollection, address indexed underlyingCollection);

    /// @notice `sender` deposit `token` into Flooring on behalf of `receiver`. `receiver`'s account will be updated.
    event DepositToken(address indexed sender, address indexed receiver, address indexed token, uint256 amount);
    /// @notice `sender` withdraw `token` from Flooring and transfer it to `receiver`.
    event WithdrawToken(address indexed sender, address indexed receiver, address indexed token, uint256 amount);
    /// @notice update the account maintain credit on behalfOf `onBehalfOf`
    event UpdateMaintainCredit(address indexed onBehalfOf, uint256 minMaintCredit);

    /// @notice Lock NFTs
    /// @param sender who send the tx and pay the NFTs
    /// @param onBehalfOf who will hold the safeboxes and receive the Fragment Tokens
    /// @param collection contract addr of the collection
    /// @param tokenIds nft ids to lock
    /// @param safeBoxKeys compacted safe box keys with same order of `tokenIds`
    /// for each key, its format is: [167-160:vipLevel][159-96:keyId][95-0:lockedCredit]
    /// @param safeBoxExpiryTs expiry timestamp of safeboxes
    /// @param minMaintCredit `onBehalfOf`'s minMaintCredit after the lock
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

    /// @notice Extend keys
    /// @param operator who extend the keys
    /// @param collection contract addr of the collection
    /// @param tokenIds nft ids to lock
    /// @param safeBoxKeys compacted safe box keys with same order of `tokenIds`
    /// for each key, its format is: [167-160:vipLevel][159-96:keyId][95-0:lockedCredit]
    /// @param safeBoxExpiryTs expiry timestamp of safeboxes
    /// @param minMaintCredit `operator`'s minMaintCredit after the lock
    event ExtendKey(
        address indexed operator,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        uint256 safeBoxExpiryTs,
        uint256 minMaintCredit
    );

    /// @notice Unlock NFTs
    /// @param operator who hold the safeboxes that will be unlocked
    /// @param receiver who will receive the NFTs
    event UnlockNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        address proxyCollection
    );

    /// @notice `operator` remove invalid keys on behalf of `onBehalfOf`.
    /// `onBehalfOf`'s account will be updated.
    event RemoveExpiredKey(
        address indexed operator,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys
    );

    /// @notice [Deprecated] Claim expired safeboxes that maintain NFTs
    /// @param operator who will pay the redemption cost
    /// @param receiver who will receive the NFTs
    /// @param creditCost how many credit token cost in this claim
    event ClaimExpiredNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        uint256 creditCost,
        address proxyCollection
    );

    /// @notice Kick expired safeboxes to the vault
    event ExpiredNftToVault(address indexed operator, address indexed collection, uint256[] tokenIds);

    /// @notice Fragment NFTs to free pool
    /// @param operator who will pay the NFTs
    /// @param onBehalfOf who will receive the Fragment Tokens
    event FragmentNft(
        address indexed operator, address indexed onBehalfOf, address indexed collection, uint256[] tokenIds
    );

    /// @notice Claim random NFTs from free pool
    /// @param operator who will pay the redemption cost
    /// @param receiver who will receive the NFTs
    /// @param creditCost how many credit token cost in this claim
    event ClaimRandomNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        uint256 creditCost
    );

    event AuctionStarted(
        address indexed trigger,
        address indexed collection,
        uint64[] activityIds,
        uint256[] tokenIds,
        address settleToken,
        uint256 minimumBid,
        uint256 feeRateBips,
        uint256 auctionEndTime,
        uint256 safeBoxExpiryTs,
        bool selfTriggered,
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

    event RaffleStarted(
        address indexed owner,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        uint48 maxTickets,
        address settleToken,
        uint96 ticketPrice,
        uint256 feeRateBips,
        uint48 raffleEndTime,
        uint256 safeBoxExpiryTs,
        uint256 adminFee
    );

    event RaffleTicketsSold(
        address indexed buyer,
        address indexed collection,
        uint64 activityId,
        uint256 nftId,
        uint256 ticketsSold,
        uint256 cost
    );

    event RaffleSettled(
        address indexed winner,
        address indexed collection,
        uint64 activityId,
        uint256 nftId,
        uint256 safeBoxKeyId,
        uint256 collectedFunds
    );

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
}
