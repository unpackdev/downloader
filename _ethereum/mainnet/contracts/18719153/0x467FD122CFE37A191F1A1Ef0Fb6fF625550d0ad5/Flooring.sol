// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./UUPSUpgradeable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./IFlooring.sol";
import "./IFlooringEvent.sol";
import "./IFragmentToken.sol";

import "./User.sol";
import "./Collection.sol";
import "./Auction.sol";
import "./Raffle.sol";
import "./PrivateOffer.sol";
import "./Structs.sol";
import "./Multicall.sol";
import "./Errors.sol";
import "./TrustedUpgradeable.sol";

contract Flooring is IFlooring, IFlooringEvent, Multicall, TrustedUpgradeable, UUPSUpgradeable, VRFConsumerBaseV2 {
    using CollectionLib for CollectionState;
    using AuctionLib for CollectionState;
    using RaffleLib for CollectionState;
    using PrivateOfferLib for CollectionState;
    using UserLib for UserFloorAccount;

    struct RandomRequestInfo {
        uint96 typ;
        address collection;
        bytes data;
    }

    /// Information related to Chainlink VRF Randomness Oracle.

    /// The keyhash, which is network dependent.
    bytes32 internal immutable keyHash;
    /// Subscription Id, need to get from the Chainlink UI.
    uint64 internal immutable subId;
    /// Chainlink VRF Coordinator.
    VRFCoordinatorV2Interface internal immutable COORDINATOR;

    /// A mapping from VRF request Id to raffle.
    mapping(uint256 => RandomRequestInfo) internal randomnessRequestToReceiver;

    /// This should be the FLC token.
    address public immutable creditToken;

    /// A mapping from collection address to `CollectionState`.
    mapping(address => CollectionState) internal collectionStates;

    /// A mapping from user address to the `UserFloorAccount`s.
    mapping(address => UserFloorAccount) internal userFloorAccounts;

    /// A mapping of supported ERC-20 token.
    mapping(address => bool) internal supportedTokens;

    /// A mapping from Proxy Collection(wrapped) to underlying Collection.
    /// eg. Paraspace Derivative Token BAYC(nBAYC) -> BAYC
    /// Note. we only use proxy collection to transfer NFTs,
    ///       all other operations should use underlying Collection.(State, Log, CollectionAccount)
    ///       proxy collection has not `CollectionState`, but use underlying collection's state.
    ///       proxy collection only is used to lock infinitly.
    ///       `fragmentNFTs` and `claimRandomNFT` don't support proxy collection
    mapping(address => address) internal collectionProxy;

    /// A mapping of collection fees configuration
    /// collectionFees[collection][token]
    /// For different tokens, we may charge different fees
    mapping(address => mapping(address => FeeConfig)) internal collectionFees;

    constructor(bytes32 _keyHash, uint64 _subId, address _vrfCoordinator, address flcToken)
        payable
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        keyHash = _keyHash;
        subId = _subId;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        creditToken = flcToken;

        _disableInitializers();
    }

    /// required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @dev just declare this as payable to reduce gas and bytecode
    function initialize() public payable initializer {
        __Trusted_init();
        __UUPSUpgradeable_init();
    }

    function supportNewCollection(address _originalNFT, address fragmentToken) public payable onlyTrusted {
        CollectionState storage collection = collectionStates[_originalNFT];
        require(collection.nextKeyId == 0);

        collection.nextKeyId = 1;
        collection.nextActivityId = 1;
        collection.floorToken = IFragmentToken(fragmentToken);

        emit NewCollectionSupported(_originalNFT, fragmentToken);
    }

    function supportNewToken(address _token, bool addOrRemove) public payable onlyTrusted {
        if (supportedTokens[_token] == addOrRemove) {
            return;
        } else {
            /// true - add
            /// false - remove
            supportedTokens[_token] = addOrRemove;
            emit UpdateTokenSupported(_token, addOrRemove);
        }
    }

    function updateCollectionFees(address collection, address[] calldata tokens, FeeConfig[] calldata fees)
        public
        payable
        onlyTrusted
    {
        for (uint256 i; i < tokens.length;) {
            collectionFees[collection][tokens[i]] = fees[i];
            unchecked {
                ++i;
            }
        }
    }

    function setCollectionProxy(address proxyCollection, address underlying) public payable onlyTrusted {
        if (collectionProxy[proxyCollection] == underlying) {
            return;
        } else {
            collectionProxy[proxyCollection] = underlying;
            emit ProxyCollectionChanged(proxyCollection, underlying);
        }
    }

    function withdrawPlatformFee(address token, uint256 amount) public payable onlyTrusted {
        /// track platform fee with account, only can withdraw fee accumulated during tx.
        /// no need to check credit token balance for the account.
        UserFloorAccount storage userFloorAccount = userFloorAccounts[address(this)];
        userFloorAccount.withdraw(msg.sender, token, amount, false);
    }

    function addAndLockCredit(address onBehalfOf, uint256 amount) public payable onlyTrusted {
        UserFloorAccount storage userFloorAccount = userFloorAccounts[onBehalfOf];
        userFloorAccount.deposit(onBehalfOf, creditToken, amount, true);
    }

    function unlockCredit(address receiver, uint256 amount) public payable onlyTrusted {
        UserFloorAccount storage userFloorAccount = userFloorAccounts[receiver];
        userFloorAccount.unlockCredit(amount);
    }

    function addTokens(address onBehalfOf, address token, uint256 amount) public payable {
        mustSupportedToken(token);

        UserFloorAccount storage userFloorAccount = userFloorAccounts[onBehalfOf];
        userFloorAccount.deposit(onBehalfOf, token, amount, false);
    }

    function removeTokens(address token, uint256 amount, address receiver) public {
        UserFloorAccount storage userFloorAccount = userFloorAccounts[msg.sender];
        userFloorAccount.withdraw(receiver, token, amount, token == creditToken);
    }

    function lockNFTs(
        address collection,
        uint256[] memory nftIds,
        uint256 expiryTs,
        uint256 vipLevel,
        uint256 maxCreditCost,
        address onBehalfOf
    ) public returns (uint256) {
        mustValidNftIds(nftIds);
        mustValidExpiryTs(expiryTs);

        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);
        return collectionState.lockNfts(
            userFloorAccounts[onBehalfOf],
            LockParam({
                proxyCollection: collection,
                collection: underlying,
                creditToken: creditToken,
                nftIds: nftIds,
                expiryTs: expiryTs,
                vipLevel: uint8(vipLevel),
                maxCreditCost: maxCreditCost
            }),
            onBehalfOf
        );
    }

    function unlockNFTs(address collection, uint256 expiryTs, uint256[] memory nftIds, address receiver) public {
        mustValidNftIds(nftIds);

        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);
        collectionState.unlockNfts(userFloorAccounts[msg.sender], collection, underlying, nftIds, expiryTs, receiver);
    }

    function removeExpiredKeyAndRestoreCredit(
        address collection,
        uint256[] memory nftIds,
        address onBehalfOf,
        bool verifyLocking
    ) public returns (uint256) {
        mustValidNftIds(nftIds);

        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);

        return userFloorAccounts[onBehalfOf].removeExpiredKeysAndRestoreCredits(
            collectionState, underlying, nftIds, onBehalfOf, verifyLocking
        );
    }

    function recalculateAvailableCredit(address onBehalfOf) public returns (uint256) {
        UserFloorAccount storage account = userFloorAccounts[onBehalfOf];

        uint256 minMaintCredit = account.recalculateMinMaintCredit(onBehalfOf);
        unchecked {
            /// when locking or extending, we ensure that `minMaintCredit` is less than `totalCredit`
            /// availableCredit = totalCredit - minMaintCredit
            return account.tokenBalance(creditToken) - minMaintCredit;
        }
    }

    function extendKeys(
        address collection,
        uint256[] memory nftIds,
        uint256 expiryTs,
        uint256 newVipLevel,
        uint256 maxCreditCost
    ) public returns (uint256) {
        mustValidNftIds(nftIds);
        mustValidExpiryTs(expiryTs);

        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);
        return collectionState.extendLockingForKeys(
            userFloorAccounts[msg.sender],
            LockParam({
                proxyCollection: collection,
                collection: underlying,
                creditToken: creditToken,
                nftIds: nftIds,
                expiryTs: expiryTs,
                vipLevel: uint8(newVipLevel),
                maxCreditCost: maxCreditCost
            })
        );
    }

    function tidyExpiredNFTs(address collection, uint256[] memory nftIds) public {
        mustValidNftIds(nftIds);
        /// expired safeboxes must not be collection
        CollectionState storage collectionState = useCollectionState(collection);
        collectionState.tidyExpiredNFTs(nftIds, collection);
    }

    function fragmentNFTs(address collection, uint256[] memory nftIds, address onBehalfOf) public {
        mustValidNftIds(nftIds);
        CollectionState storage collectionState = useCollectionState(collection);

        collectionState.fragmentNFTs(userFloorAccounts[onBehalfOf], collection, nftIds, onBehalfOf);
    }

    function claimRandomNFT(address collection, uint256 claimCnt, uint256 maxCreditCost, address receiver)
        public
        returns (uint256)
    {
        CollectionState storage collectionState = useCollectionState(collection);

        return collectionState.claimRandomNFT(
            userFloorAccounts, collectionFees[collection], collection, claimCnt, maxCreditCost, receiver
        );
    }

    function initAuctionOnVault(address collection, uint256[] memory vaultIdx, address bidToken, uint96 bidAmount)
        public
    {
        mustValidNftIds(vaultIdx);
        CollectionState storage collectionState = useCollectionState(collection);
        collectionState.initAuctionOnVault(
            userFloorAccounts,
            collectionFees[collection][bidToken],
            creditToken,
            collection,
            vaultIdx,
            bidToken,
            bidAmount
        );
    }

    function initAuctionOnExpiredSafeBoxes(
        address collection,
        uint256[] memory nftIds,
        address bidToken,
        uint256 bidAmount
    ) public {
        mustValidNftIds(nftIds);
        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);
        collectionState.initAuctionOnExpiredSafeBoxes(
            userFloorAccounts,
            collectionFees[underlying][bidToken],
            creditToken,
            underlying,
            nftIds,
            bidToken,
            bidAmount
        );
    }

    function ownerInitAuctions(
        address collection,
        uint256[] memory nftIds,
        uint256 maxExpiry,
        address token,
        uint256 minimumBid
    ) public {
        mustValidNftIds(nftIds);

        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);
        collectionState.ownerInitAuctions(
            userFloorAccounts,
            collectionFees[underlying][token],
            creditToken,
            underlying,
            nftIds,
            maxExpiry,
            token,
            minimumBid
        );
    }

    function placeBidOnAuction(address collection, uint256 nftId, uint256 bidAmount, uint256 bidOptionIdx)
        public
        payable
    {
        if (msg.value > 0) addTokens(msg.sender, CurrencyTransfer.NATIVE, msg.value);
        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);
        collectionState.placeBidOnAuction(userFloorAccounts, creditToken, underlying, nftId, bidAmount, bidOptionIdx);
    }

    function settleAuctions(address collection, uint256[] memory nftIds) public {
        mustValidNftIds(nftIds);
        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collection);
        collectionState.settleAuctions(userFloorAccounts, underlying, nftIds);
    }

    function ownerInitRaffles(RaffleInitParam memory param) public {
        mustValidNftIds(param.nftIds);

        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(param.collection);
        param.collection = underlying;

        collectionState.ownerInitRaffles(
            userFloorAccounts, collectionFees[underlying][param.ticketToken], param, creditToken
        );
    }

    function buyRaffleTickets(address collectionId, uint256 nftId, uint256 ticketCnt) public payable {
        if (msg.value > 0) addTokens(msg.sender, CurrencyTransfer.NATIVE, msg.value);
        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collectionId);

        collectionState.buyRaffleTickets(userFloorAccounts, creditToken, underlying, nftId, ticketCnt);
    }

    function settleRaffles(address collectionId, uint256[] memory nftIds) public {
        mustValidNftIds(nftIds);
        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collectionId);

        (bytes memory toSettleNftIds, uint256 len) = collectionState.prepareSettleRaffles(nftIds);
        if (len > 0) {
            uint256 requestId = COORDINATOR.requestRandomWords(keyHash, subId, 3, 800_000, uint32(len));
            randomnessRequestToReceiver[requestId] =
                RandomRequestInfo({typ: 1, collection: underlying, data: toSettleNftIds});
        }
    }

    function _completeSettleRaffles(address collectionId, bytes memory data, uint256[] memory randoms) private {
        CollectionState storage collection = collectionStates[collectionId];
        collection.settleRaffles(userFloorAccounts, collectionId, data, randoms);
    }

    function ownerInitPrivateOffers(PrivateOfferInitParam memory param) public {
        mustValidNftIds(param.nftIds);

        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(param.collection);
        param.collection = underlying;
        collectionState.ownerInitPrivateOffers(
            userFloorAccounts, collectionFees[underlying][param.token], creditToken, param
        );
    }

    function modifyOffers(address collectionId, uint256[] memory nftIds, OfferOpType opTy, bytes calldata data)
        public
    {
        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collectionId);
        collectionState.modifyOffers(userFloorAccounts, underlying, nftIds, opTy, data);
    }

    function buyerAcceptPrivateOffers(address collectionId, uint256[] memory nftIds, uint256 maxSafeboxExpiry)
        public
        payable
    {
        mustValidNftIds(nftIds);
        if (msg.value > 0) addTokens(msg.sender, CurrencyTransfer.NATIVE, msg.value);
        (CollectionState storage collectionState, address underlying) = useUnderlyingCollectionState(collectionId);
        collectionState.buyerAcceptPrivateOffers(userFloorAccounts, underlying, creditToken, nftIds, maxSafeboxExpiry);
    }

    function extMulticall(CallData[] calldata calls)
        external
        override(Multicall, IMulticall)
        onlyTrusted
        returns (bytes[] memory)
    {
        return multicall2(calls);
    }

    function onERC721Received(address, /*operator*/ address, /*from*/ uint256, /*tokenId*/ bytes calldata /*data*/ )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function useUnderlyingCollectionState(address collectionId)
        private
        view
        returns (CollectionState storage, address)
    {
        address underlying = collectionProxy[collectionId];
        if (underlying == address(0)) {
            underlying = collectionId;
        }

        return (useCollectionState(underlying), underlying);
    }

    function useCollectionState(address collectionId) private view returns (CollectionState storage) {
        CollectionState storage collection = collectionStates[collectionId];
        if (collection.nextKeyId == 0) revert Errors.NftCollectionNotSupported();
        return collection;
    }

    function mustSupportedToken(address token) private view {
        if (!supportedTokens[token]) revert Errors.TokenNotSupported();
    }

    function mustValidNftIds(uint256[] memory nftIds) private pure {
        if (nftIds.length == 0) revert Errors.InvalidParam();

        /// nftIds should be ordered and there should be no duplicate elements.
        for (uint256 i = 1; i < nftIds.length;) {
            unchecked {
                if (nftIds[i] <= nftIds[i - 1]) {
                    revert Errors.InvalidParam();
                }
                ++i;
            }
        }
    }

    function mustValidExpiryTs(uint256 expiryTs) private view {
        if (expiryTs != 0 && expiryTs <= block.timestamp) revert Errors.InvalidParam();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        RandomRequestInfo storage info = randomnessRequestToReceiver[requestId];

        _completeSettleRaffles(info.collection, info.data, randomWords);

        delete randomnessRequestToReceiver[requestId];
    }

    function collectionLockingAt(address collection, uint256 startTimestamp, uint256 endTimestamp)
        public
        view
        returns (uint256[] memory)
    {
        return collectionStates[collection].getLockingBuckets(startTimestamp, endTimestamp);
    }

    function extsload(bytes32 slot) external view returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := sload(slot)
        }
    }

    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes memory) {
        bytes memory value = new bytes(nSlots << 5);

        /// @solidity memory-safe-assembly
        assembly {
            for { let i := 0 } lt(i, nSlots) { i := add(i, 1) } {
                mstore(add(value, shl(5, add(i, 1))), sload(add(startSlot, i)))
            }
        }

        return value;
    }

    receive() external payable {
        addTokens(msg.sender, CurrencyTransfer.NATIVE, msg.value);
    }
}
