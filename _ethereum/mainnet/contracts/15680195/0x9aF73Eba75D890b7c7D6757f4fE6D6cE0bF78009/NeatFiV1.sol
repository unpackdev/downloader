// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NeatFiProtocolOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title NeatFiV1
 * @author NeatFi
 * @notice The main contract of the NeatFi protocol that interacts with the
 *         protocol module and contract implementations through their interfaces.
 *         NeatFi can be operated by Actor contract implementations. Actors need
 *         to requeest actor keys to be able to get verified and approved in order
 *         to interact with the NeatFi contract through its INeatFi interface.
 */

contract NeatFiV1 is
    NeatFiProtocolOperationsUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    string internal name;
    string internal currentVersion;

    /**
     * Administrative operations
     */

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @dev An external function to update the address of the implementation
     *      contract of NeatFi's Asset Swap module. Can be executed by
     *      a Protocol Admin only.
     * @param newSwapModule - The address of the new Asset Swap module
     *                        implementation contract.
     */
    function setSwapModule(address newSwapModule)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        swapModule = newSwapModule;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Asset Sell module. Can be executed by
     *      a Protocol Admin only.
     * @param newSellModule - The address of the new Asset Sell module
     *                        implementation contract.
     */
    function setSellModule(address newSellModule)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        sellModule = newSellModule;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Asset Sell module. Can be executed by
     *      a Protocol Admin only.
     * @param newAuctionModule - The address of the new Asset Sell module
     *                        implementation contract.
     */
    function setAuctionModule(address newAuctionModule)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        auctionModule = newAuctionModule;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Payment Resolver contract. Can be executed by
     *      a Protocol Admin only.
     * @param newPaymentsResolver - The address of the new Payment Resolver
     *                        implementation contract.
     */
    function setPaymentsResolver(address newPaymentsResolver)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        paymentsResolver = newPaymentsResolver;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Protocol Storage contract. Can be executed by
     *      a Protocol Admin only.
     * @param newProtocolStorage - The address of the new Protocol Storage
     *                        implementation contract.
     */
    function setProtocolStorage(address newProtocolStorage)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        protocolStorage = newProtocolStorage;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Protocol Settings contract. Can be executed by
     *      a Protocol Admin only.
     * @param newProtocolSettings - The address of the new Protocol Settings
     *                        implementation contract.
     */
    function setProtocolSettings(address newProtocolSettings)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        protocolSettings = newProtocolSettings;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Protocol Treasury contract. Can be executed by
     *      a Protocol Admin only.
     * @param newProtocolTreasury - The address of the new Protocol Treasury
     *                        implementation contract.
     */
    function setProtocolTreasury(address payable newProtocolTreasury)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        protocolTreasury = newProtocolTreasury;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Actor Factory contract. Can be executed by
     *      a Protocol Admin only.
     * @param newActorFactory - The address of the new Actor Factory
     *                        implementation contract.
     */
    function setActorFactory(address newActorFactory)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        actorFactory = newActorFactory;
    }

    /**
     * Protocol Settings operations
     */

    /**
     * @dev An external function to retrieve the protocol fee
     *      numerator for Swap Order creation.
     * @return sellProtocolFee - The protocol fee numerator for
     *                           a Swap Order creation.
     */

    function getSwapProtocolFee()
        external
        view
        returns (uint256 sellProtocolFee)
    {
        return _getSwapProtocolFee();
    }

    /**
     * Actor Factory operations
     */

    /**
     * @dev Requests an actor key from NeatFi's Actor Factory contract.
     *      Protocol Admins approve requests and generate actor keys.
     *      Actors need to have valid actor keys and an ACTIVE status in
     *      order to interact with the NeatFi contract.
     * @param actorAddress - The address of the Actor contract.
     */
    function requestActorKey(address actorAddress) external nonReentrant {
        _requestActorKey(actorAddress);
    }

    /**
     * @dev An external function to change the fee distribution
     *      address for an Actor.
     * @param actorAddress - The address of the Actor contract.
     * @param newFeeDistributionAddress - The new receiver address
     *                                    of protocol fees.
     */
    function changeFeeDistributionAddress(
        address actorAddress,
        address payable newFeeDistributionAddress
    ) external nonReentrant {
        _changeFeeDistributionAddress(actorAddress, newFeeDistributionAddress);
    }

    /**
     * @dev An external function to retrieve the fee distribution
     *      address of an Actor.
     * @param actorAddress - The address of the Actor.
     * @return feeDistributionAddress - The address of fee distribution.
     */
    function getFeeDistributionAddress(address actorAddress)
        external
        view
        returns (address payable feeDistributionAddress)
    {
        return _getFeeDistributionAddress(actorAddress);
    }

    /**
     * Protocol Storage operations
     */

    /**
     * @dev An external payable function to make an Order asset. For Swap
     *      Orders, msg.value must be equal to the protocol fee for Swap
     *      Order creation. For other Orders, it should be 0.
     *      Message sender should be an active Actor contract.
     * @param tokens - The array of Token assets to be included in the Order.
     * @param orderType - The enum ype of an Order.
     *                    0 - SELL,
     *                    1 - ENGLISH_AUCTION,
     *                    2 - DUTCH_AUCTION,
     *                    3 - SWAP
     *                    4 - BID
     * @param maker - The address of the Order maker.
     * @param listingTime - The timestamp of Order creation.
     * @param expirationTime - The expiration timestamp of the Order.
     * @param startPrice - The starting price of the Order.
     * @param actorKey - The actor key of the Actor contract.
     * @return orderHash - The hash of the Order.
     */
    function makeOrder(
        Token[] calldata tokens,
        AssetOrderType orderType,
        address payable maker,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 startPrice,
        bytes32 actorKey
    )
        external
        payable
        nonReentrant
        onlyActor(msg.sender)
        returns (bytes32 orderHash)
    {
        return
            _makeOrder(
                msg.sender,
                tokens,
                orderType,
                maker,
                msg.value,
                listingTime,
                expirationTime,
                startPrice,
                actorKey
            );
    }

    /**
     * @dev An external function to make a Bid Order for a Swap Order.
     *      Message sender should be an active Actor contract.
     * @param tokens - The array of Token assets to be included in the Bid.
     * @param bidder - The address of the bidder.
     * @param listingTime - The timestamp of the creation of the Bid.
     * @param orderHash - The hash of the Swap Order.
     * @param actorKey - The actor key of the Actor contract.
     * @return bidHash - The hash of the Bid type Order.
     */
    function makeBid(
        Token[] calldata tokens,
        address bidder,
        uint256 listingTime,
        bytes32 orderHash,
        bytes32 actorKey
    ) external nonReentrant onlyActor(msg.sender) returns (bytes32 bidHash) {
        return _makeBid(bidder, tokens, listingTime, orderHash, actorKey);
    }

    /**
     * @dev An external function for the Order maker to cancel the Order.
     *      Message sender should be an active Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     */
    function cancelOrder(address maker, bytes32 orderHash)
        external
        onlyActor(msg.sender)
    {
        _cancelOrder(msg.sender, maker, orderHash);
    }

    /**
     * @dev An external function for the Order maker to approve
     *      and resolve a Swap Order. Message sender should be
     *      an active Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param bidHash - The hash of the Bid type Order.
     * @param orderData - Optional additional data to include with the transaction.
     * @param bidData - Optional additional data to include with the transaction.
     */
    function approveAndResolveSwap(
        address maker,
        bytes32 orderHash,
        bytes32 bidHash,
        bytes calldata orderData,
        bytes calldata bidData
    ) external nonReentrant onlyActor(msg.sender) {
        _approveAndResolveSwap(
            msg.sender,
            maker,
            orderHash,
            bidHash,
            orderData,
            bidData
        );
    }

    /**
     * @dev An external function for the buyer to immediately
     *         buy Token assets of a Sell Order. Message sender should be
     *         an active Actor contract.
     * @param buyer - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param data - Optional additional data to include with the transaction.
     */
    function buyItNow(
        address buyer,
        bytes32 orderHash,
        bytes calldata data
    ) external payable nonReentrant onlyActor(msg.sender) {
        _buyItNow(msg.sender, orderHash, msg.value, buyer, data);
    }

    /**
     * @dev Maker decreases the price of a Dutch Auction.
     *      Message sender should be an active Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new end price of the Order.
     */
    function decreaseDucthAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external nonReentrant onlyActor(msg.sender) {
        _decreaseDucthAuctionPrice(msg.sender, maker, orderHash, newPrice);
    }

    /**
     * @dev Maker increases the price of an English Auction.
     *      Message sender should be an active Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new end price of the Order.
     */
    function increaseEnglishAuctionPrice(
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) external nonReentrant onlyActor(msg.sender) {
        _increaseEnglishAuctionPrice(msg.sender, maker, orderHash, newPrice);
    }

    /**
     * @dev The bidder commits native tokens (i.e. Eth for Ethereum) for an
     *         English Auction. The native tokens are not transferred from the
     *         bidder yet. Message sender should be an active Actor contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The committment of the bidder in native tokens.
     */
    function bidForEnglishAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external nonReentrant onlyActor(msg.sender) {
        _bidForEnglishAuction(msg.sender, bidder, orderHash, bidValue);
    }

    /**
     * @dev The bidder commits native tokens (i.e. Eth for Ethereum) for a
     *         Dutch Auction. The native tokens are not transferred from the
     *         bidder yet. Message sender should be an active Actor contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The committment of the bidder in native tokens.
     */
    function bidForDutchAuction(
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) external nonReentrant onlyActor(msg.sender) {
        _bidForDutchAuction(msg.sender, bidder, orderHash, bidValue);
    }

    /**
     * @dev The maker approves the last bid in native tokens.
            Message sender should be an active Actor contract.
     * @param maker - The address of the maker.
     * @param orderHash - The hash of the Order.
     */
    function approveLastBid(address maker, bytes32 orderHash)
        external
        nonReentrant
        onlyActor(msg.sender)
    {
        _approveLastBid(msg.sender, maker, orderHash);
    }

    /**
     * @dev The approved bidder claims the English Auction Order.
     *      Message sender should be an active Actor contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param data - Optional additional data to include with the transaction.
     */
    function claimEnglishAuction(
        address bidder,
        bytes32 orderHash,
        bytes calldata data
    ) external payable nonReentrant onlyActor(msg.sender) {
        _claimEnglishAuction(msg.sender, bidder, orderHash, msg.value, data);
    }

    /**
     * @dev The approved bidder claims the Dutch Auction Order.
     *      Message sender should be an active Actor contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param data - Optional additional data to include with the transaction.
     */
    function claimDutchAuction(
        address bidder,
        bytes32 orderHash,
        bytes calldata data
    ) external payable nonReentrant onlyActor(msg.sender) {
        _claimDutchAuction(msg.sender, bidder, orderHash, msg.value, data);
    }

    /** Initializers  */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(
        address swapModuleAddress,
        address sellModuleAddress,
        address auctionModuleAddress,
        address paymentsResolverAddress,
        address protocolSettingsAddress,
        address protocolStorageAddress,
        address actorFactoryAddress,
        address payable protocolTreasuryAddress
    ) public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __NeatFiProtocolOperations_init(
            swapModuleAddress,
            sellModuleAddress,
            auctionModuleAddress,
            paymentsResolverAddress,
            protocolSettingsAddress,
            protocolStorageAddress,
            actorFactoryAddress,
            protocolTreasuryAddress
        );
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = "NeatFi Protocol";
        _setVersion("1.0.0");
    }
}
