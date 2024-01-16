// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./INeatFiProtocolStorage.sol";
import "./IAssetSwap.sol";
import "./IAssetSell.sol";
import "./IAssetAuction.sol";
import "./IPaymentsResolver.sol";
import "./IProtocolSettings.sol";
import "./IActorFactory.sol";
import "./RoleConstantsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";
import "./AssetStructsUpgradeable.sol";

/**
 * @title NeatFiProtocolOperationsUpgradeable
 * @author NeatFi
 * @notice This contract implements the operations for the NeatFi modules.
 */
contract NeatFiProtocolOperationsUpgradeable is
    RoleConstantsUpgradeable,
    AccessControlUpgradeable,
    AssetEnumsUpgradeable,
    AssetStructsUpgradeable
{
    address public swapModule;
    address public sellModule;
    address public auctionModule;
    address public paymentsResolver;
    address public protocolStorage;
    address public protocolSettings;
    address public actorFactory;
    address payable public protocolTreasury;

    /**
     * Protocol Administration
     *
     * @dev NeatFi Protocol contracts are upgradeable via a UUPSUpgradeable
     *      proxy, and, while implementation contracts are subjects to updates,
     *      it is not expected that the address of the proxy should be changed.
     *      Therefore, the functions below are for emergency situations ONLY to
     *      be executed by a Protocol Admin and with the knowledge of the NeatFi
     *      Community.
     */

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Asset Swap module.
     * @param newSwapModule - The address of the new Asset Swap module
     *                        implementation contract.
     */
    function _setSwapModule(address newSwapModule) internal {
        swapModule = newSwapModule;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Asset Sell module.
     * @param newSellModule - The address of the new Asset Sell module
     *                        implementation contract.
     */
    function _setSellModule(address newSellModule) internal {
        sellModule = newSellModule;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Asset Sell module.
     * @param newAuctionModule - The address of the new Asset Sell module
     *                        implementation contract.
     */
    function _setAuctionModule(address newAuctionModule) internal {
        auctionModule = newAuctionModule;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Payment Resolver contract.
     * @param newPaymentsResolver - The address of the new Payment Resolver
     *                        implementation contract.
     */
    function _setPaymentsResolver(address newPaymentsResolver) internal {
        paymentsResolver = newPaymentsResolver;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Protocol Storage contract.
     * @param newProtocolStorage - The address of the new Protocol Storage
     *                        implementation contract.
     */
    function _setProtocolStorage(address newProtocolStorage) internal {
        protocolStorage = newProtocolStorage;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Protocol Settings contract.
     * @param newProtocolSettings - The address of the new Protocol Settings
     *                        implementation contract.
     */
    function _setProtocolSettings(address newProtocolSettings) internal {
        protocolSettings = newProtocolSettings;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Protocol Treasury contract.
     * @param newProtocolTreasury - The address of the new Protocol Treasury
     *                        implementation contract.
     */
    function _setProtocolTreasury(address payable newProtocolTreasury)
        internal
    {
        protocolTreasury = newProtocolTreasury;
    }

    /**
     * @dev An internal function to update the address of the implementation
     *      contract of NeatFi's Actor Factory contract.
     * @param newActorFactory - The address of the new Actor Factory
     *                        implementation contract.
     */
    function _setActorFactory(address newActorFactory) internal {
        actorFactory = newActorFactory;
    }

    /**
     * @dev Verifies that the message sender is an active Actor with a
     *      valid actor key.
     */
    modifier onlyActor(address actorAddress) {
        require(
            IActorFactory(actorFactory).getActorKey(actorAddress) != 0x0,
            "NeatFiProtocolOperationsUpgradeable::onlyActor: caller is not an Actor."
        );
        _;
    }

    /**
     * Actor Factory operations implmenetation
     */

    /**
     * @dev An internal function to request an actor key from NeatFi's
     *      Actor Factory contract.
     * @param actorAddress - The address of the Actor contract.
     */
    function _requestActorKey(address actorAddress) internal {
        IActorFactory(actorFactory).requestActorKey(actorAddress);
    }

    /**
     * @dev An internal function to assess the validity of an actor key
     *      in regards to an Actor address and an Order asset.
     * @param actorAddress - The address of the Actor contract.
     * @param orderHash - The hash of the Order.
     * @return The validity assessment result.
     */
    function _isValidActorKey(address actorAddress, bytes32 orderHash)
        internal
        view
        returns (bool)
    {
        bytes32 actorKey = IActorFactory(actorFactory).getActorKey(
            actorAddress
        );

        return
            INeatFiProtocolStorage(protocolStorage).isValidActorKey(
                orderHash,
                actorKey
            );
    }

    /**
     * @dev An internal function to change the fee distribution
     *      address for an Actor.
     * @param actorAddress - The address of the Actor contract.
     * @param newFeeDistributionAddress - The new receiver address
     *                                    of protocol fees.
     */
    function _changeFeeDistributionAddress(
        address actorAddress,
        address payable newFeeDistributionAddress
    ) internal {
        IActorFactory(actorFactory).changeFeeDistributionAddress(
            actorAddress,
            newFeeDistributionAddress
        );
    }

    /**
     * @dev An internal function to retrieve the fee distribution
     *      address of an Actor.
     * @param actorAddress - The address of the Actor.
     * @return feeDistributionAddress - The address of fee distribution.
     */
    function _getFeeDistributionAddress(address actorAddress)
        internal
        view
        returns (address payable feeDistributionAddress)
    {
        return
            IActorFactory(actorFactory).getFeeDistributionAddress(actorAddress);
    }

    /**
     * Protocol Settings operations implementation
     */

    /**
     * @dev An internal function to retrieve the protocol fee
     *      numerator for English Auction Order settlements.
     * @return englishAuctionProtocolFee - The protocol fee numerator for
     *                                     an English Auction settlment.
     */
    function _getEnglishAuctionProtocolFeeNumerator()
        internal
        view
        returns (uint256 englishAuctionProtocolFee)
    {
        return
            IProtocolSettings(protocolSettings)
                .getEnglishAuctionProtocolFeeNumerator();
    }

    /**
     * @dev An internal function to retrieve the protocol fee
     *      numerator for Dutch Auction Order settlements.
     * @return dutchAuctionProtocolFee - The protocol fee numerator for
     *                                     a Dutch Auction settlment.
     */
    function _getDutchAuctionProtocolFeeNumerator()
        internal
        view
        returns (uint256 dutchAuctionProtocolFee)
    {
        return
            IProtocolSettings(protocolSettings)
                .getDutchAuctionProtocolFeeNumerator();
    }

    /**
     * @dev An internal function to retrieve the protocol fee
     *      numerator for Sell Order settlements.
     * @return sellProtocolFee - The protocol fee numerator for
     *                                     a Sell Order settlment.
     */
    function _getSellProtocolFeeNumerator()
        internal
        view
        returns (uint256 sellProtocolFee)
    {
        return
            IProtocolSettings(protocolSettings).getSellProtocolFeeNumerator();
    }

    /**
     * @dev An internal function to retrieve the protocol fee
     *      numerator for Swap Order creation.
     * @return sellProtocolFee - The protocol fee numerator for
     *                                     a Swap Order creation.
     */
    function _getSwapProtocolFee()
        internal
        view
        returns (uint256 sellProtocolFee)
    {
        return IProtocolSettings(protocolSettings).getSwapProtocolFee();
    }

    function _transferHelper(
        address payable to,
        uint256 amount,
        string memory errorMessage
    ) internal {
        require(
            address(this).balance >= amount,
            "NeatFiProtocolOperationsUpgradeable::_transferHelper: not enought Ether on the contract balance."
        );

        (bool sent, bytes memory data) = to.call{value: amount}("");
        require(sent, errorMessage);
    }

    /**
     * Protocol Storage operations implementation
     */

    /**
     * @dev An internal function to make an Order asset.
     * @param tokens - The array of Token assets to be included in the Order.
     * @param maker - The address of the Order maker.
     * @param value - The protocol fee for Order creation. Only for Swap Orders,
     *                0 for others.
     * @param listingTime - The timestamp of Order creation.
     * @param expirationTime - The expiration timestamp of the Order.
     * @param startPrice - The starting price of the Order.
     * @param actorKey - The actor key of the Actor contract.
     * @return orderHash - The hash of the Order.
     */
    function _makeOrder(
        address actorAddress,
        Token[] calldata tokens,
        AssetOrderType orderType,
        address payable maker,
        uint256 value,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 startPrice,
        bytes32 actorKey
    ) internal returns (bytes32 orderHash) {
        if (orderType == AssetOrderType.SWAP) {
            require(
                value == _getSwapProtocolFee(),
                "NeatFiProtocolOperationsUpgradeable::_makeOrder: wrong value for SWAP protocol fee."
            );

            // Actor earnings distribution

            uint256 actorEarningsNumerator = IProtocolSettings(protocolSettings)
                .getActorEarningsNumerator();

            uint256 actorEarnings = value -
                (value * actorEarningsNumerator) /
                1000;

            address payable actorFeeDistributionAddress = IActorFactory(
                actorFactory
            ).getFeeDistributionAddress(actorAddress);

            uint256 netProtocolFee = value - actorEarnings;

            _transferHelper(
                actorFeeDistributionAddress,
                actorEarnings,
                "NeatFiProtocolOperationsUpgradeable::_makeOrder: failed to actor earnings."
            );

            // Protocol fee distribution

            _transferHelper(
                protocolTreasury,
                netProtocolFee,
                "NeatFiProtocolOperationsUpgradeable::_makeOrder: failed to send protocol fee."
            );
        } else {
            require(
                value == 0,
                "NeatFiProtocolOperationsUpgradeable::_makeOrder: value should be 0."
            );
        }

        return
            INeatFiProtocolStorage(protocolStorage).makeOrder(
                tokens,
                orderType,
                maker,
                listingTime,
                expirationTime,
                startPrice,
                startPrice, // At the Order creation, the start and end prices are equal
                actorKey
            );
    }

    /**
     * @dev An internal function to make a Bid Order for a Swap Order.
     * @param bidder - The address of the bidder.
     * @param tokens - The array of Token assets to be included in the Bid.
     * @param listingTime - The timestamp of the creation of the Bid.
     * @param orderHash - The hash of the Swap Order.
     * @param actorKey - The actor key of the Actor contract.
     * @return bidHash - The hash of the Bid type Order.
     */
    function _makeBid(
        address bidder,
        Token[] calldata tokens,
        uint256 listingTime,
        bytes32 orderHash,
        bytes32 actorKey
    ) internal returns (bytes32 bidHash) {
        return
            IAssetSwap(swapModule).makeBid(
                bidder,
                tokens,
                listingTime,
                orderHash,
                actorKey
            );
    }

    /**
     * @dev An internal function to cancel an Order by its maker.
     * @param actorAddress - The address of the Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     */
    function _cancelOrder(
        address actorAddress,
        address maker,
        bytes32 orderHash
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        require(
            INeatFiProtocolStorage(protocolStorage).isValidOwner(
                orderHash,
                maker
            )
        );

        INeatFiProtocolStorage(protocolStorage).changeOrderStatus(
            orderHash,
            AssetOrderStatus.CANCELLED
        );
    }

    /**
     * Asset Swap module operations implementation
     */

    /**
     * @dev An internal function to approve and resolve a Swap Order.
     * @param actorAddress - The address of the Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param bidHash - The hash of the Bid type Order.
     * @param orderData - Optional additional data to include with the transaction.
     * @param bidData - Optional additional data to include with the transaction.
     */
    function _approveAndResolveSwap(
        address actorAddress,
        address maker,
        bytes32 orderHash,
        bytes32 bidHash,
        bytes calldata orderData,
        bytes calldata bidData
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));
        require(_isValidActorKey(actorAddress, bidHash));

        IAssetSwap(swapModule).approveAndResolveSwap(
            maker,
            orderHash,
            bidHash,
            orderData,
            bidData
        );
    }

    /**
     * Asset Sell module operations implementation
     */

    /**
     * @dev An internal function to purchase a Sell Order.
     * @param actorAddress - The address of the Actor contract.
     * @param orderHash - The hash of the Order.
     * @param purchaseValue - The value in native tokens to be paid
     *                        for the Sell Order settlment.
     * @param bidder - The address of the bidder.
     * @param data - Optional additional data to include with the transaction.
     */
    function _buyItNow(
        address actorAddress,
        bytes32 orderHash,
        uint256 purchaseValue,
        address bidder,
        bytes calldata data
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        // Maker earnings distribution

        address payable maker = INeatFiProtocolStorage(protocolStorage)
            .getOrderMaker(orderHash);

        uint256 makerEarnings = IPaymentsResolver(paymentsResolver)
            .sellFeeResolver(purchaseValue);

        // Actor earnings distribution

        uint256 grossProtocolFee = purchaseValue - makerEarnings;

        uint256 actorEarningsNumerator = IProtocolSettings(protocolSettings)
            .getActorEarningsNumerator();

        uint256 actorEarnings = (grossProtocolFee * actorEarningsNumerator) /
            (1000);

        address payable actorFeeDistributionAddress = IActorFactory(
            actorFactory
        ).getFeeDistributionAddress(actorAddress);

        // Protocol fee distribution

        uint256 netProtocolFee = grossProtocolFee - actorEarnings;

        // Resolving fee transfers

        _transferHelper(
            maker,
            makerEarnings,
            "NeatFiProtocolOperationsUpgradeable::_buyItNow: failed to send maker earnings."
        );

        _transferHelper(
            actorFeeDistributionAddress,
            actorEarnings,
            "NeatFiProtocolOperationsUpgradeable::_buyItNow: failed to send actor earnings."
        );

        _transferHelper(
            protocolTreasury,
            netProtocolFee,
            "NeatFiProtocolOperationsUpgradeable::_buyItNow: failed to send protocol fee."
        );

        IAssetSell(sellModule).buyItNow(orderHash, purchaseValue, bidder, data);
    }

    /**
     * Asset Auction module operations implementation
     */

    /**
     * @dev An internal function to decrease the price of a
     *      Ducth Auction Order.
     * @param actorAddress - The address of the Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new end price of the Order.
     */
    function _decreaseDucthAuctionPrice(
        address actorAddress,
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        IAssetAuction(auctionModule).decreaseDucthAuctionPrice(
            maker,
            orderHash,
            newPrice
        );
    }

    /**
     * @dev An internal function to increase the price of a
     *      English Auction Order.
     * @param actorAddress - The address of the Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param newPrice - The new end price of the Order.
     */
    function _increaseEnglishAuctionPrice(
        address actorAddress,
        address maker,
        bytes32 orderHash,
        uint256 newPrice
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        IAssetAuction(auctionModule).increaseEnglishAuctionPrice(
            maker,
            orderHash,
            newPrice
        );
    }

    /**
     * @dev An internal function to commit native tokens
     *      (i.e. Eth for Ethereum) for an English Auction Order.
     * @param actorAddress - The address of the Actor contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The bid committment in native tokens.
     */
    function _bidForEnglishAuction(
        address actorAddress,
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        IAssetAuction(auctionModule).bidForEnglishAuction(
            bidder,
            orderHash,
            bidValue
        );
    }

    /**
     * @dev An internal function to commit native tokens
     *      (i.e. Eth for Ethereum) for a Dutch Auction Order.
     * @param actorAddress - The address of the Actor contract.
     * @param bidder - The address of the bidder.
     * @param orderHash - The hash of the Order.
     * @param bidValue - The bid committment in native tokens.
     */
    function _bidForDutchAuction(
        address actorAddress,
        address bidder,
        bytes32 orderHash,
        uint256 bidValue
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        IAssetAuction(auctionModule).bidForDutchAuction(
            bidder,
            orderHash,
            bidValue
        );
    }

    /**
     * @dev An internal function to approve the last bid committment
     *      by the Auction Order maker (English/Dutch).
     * @param actorAddress - The address of the Actor contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     */
    function _approveLastBid(
        address actorAddress,
        address maker,
        bytes32 orderHash
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        IAssetAuction(auctionModule).approveLastBid(maker, orderHash);
    }

    /**
     * @dev An internal function to claim an English Auction Order
     *      assets by the approved bidder.
     * @param actorAddress - The address of the Actor contract.
     * @param bidder - The address of the approved bidder.
     * @param orderHash - The hash of the Order.
     * @param purchaseValue - The end price of the Order in native tokens.
     * @param data - Optional additional data to include with the transaction.
     */
    function _claimEnglishAuction(
        address actorAddress,
        address bidder,
        bytes32 orderHash,
        uint256 purchaseValue,
        bytes calldata data
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        // Maker earnings distribution

        address payable maker = INeatFiProtocolStorage(protocolStorage)
            .getOrderMaker(orderHash);

        uint256 makerEarnings = IPaymentsResolver(paymentsResolver)
            .englishAuctionFeeResolver(purchaseValue);

        // Actor earnings distribution

        uint256 grossProtocolFee = purchaseValue - makerEarnings;

        uint256 actorEarningsNumerator = IProtocolSettings(protocolSettings)
            .getActorEarningsNumerator();

        uint256 actorEarnings = grossProtocolFee -
            (grossProtocolFee * actorEarningsNumerator) /
            1000;

        address payable actorFeeDistributionAddress = IActorFactory(
            actorFactory
        ).getFeeDistributionAddress(actorAddress);

        // Protocol fee distribution

        uint256 netProtocolFee = grossProtocolFee - actorEarnings;

        _transferHelper(
            maker,
            makerEarnings,
            "NeatFiProtocolOperationsUpgradeable::_claimEnglishAuction: failed to send maker earnings."
        );

        _transferHelper(
            actorFeeDistributionAddress,
            actorEarnings,
            "NeatFiProtocolOperationsUpgradeable::_claimEnglishAuction: failed to actor earnings."
        );

        _transferHelper(
            protocolTreasury,
            netProtocolFee,
            "NeatFiProtocolOperationsUpgradeable::_claimEnglishAuction: failed to send protocol fee."
        );

        IAssetAuction(auctionModule).claimAuction(bidder, orderHash, data);
    }

    /**
     * @dev An internal function to claim a Dutch Auction Order
     *      assets by the approved bidder.
     * @param actorAddress - The address of the Actor contract.
     * @param bidder - The address of the approved bidder.
     * @param orderHash - The hash of the Order.
     * @param purchaseValue - The end price of the Order in native tokens.
     * @param data - Optional additional data to include with the transaction.
     */
    function _claimDutchAuction(
        address actorAddress,
        address bidder,
        bytes32 orderHash,
        uint256 purchaseValue,
        bytes calldata data
    ) internal {
        require(_isValidActorKey(actorAddress, orderHash));

        // Maker earnings distribution

        address payable maker = INeatFiProtocolStorage(protocolStorage)
            .getOrderMaker(orderHash);

        uint256 makerEarnings = IPaymentsResolver(paymentsResolver)
            .dutchAuctionFeeResolver(purchaseValue);

        // Actor earnings distribution

        uint256 grossProtocolFee = purchaseValue - makerEarnings;

        uint256 actorEarningsNumerator = IProtocolSettings(protocolSettings)
            .getActorEarningsNumerator();

        uint256 actorEarnings = grossProtocolFee -
            (grossProtocolFee * actorEarningsNumerator) /
            1000;

        address payable actorFeeDistributionAddress = IActorFactory(
            actorFactory
        ).getFeeDistributionAddress(actorAddress);

        // Protocol fee distribution

        uint256 netProtocolFee = grossProtocolFee - actorEarnings;

        _transferHelper(
            maker,
            makerEarnings,
            "NeatFiProtocolOperationsUpgradeable::_claimDutchAuction: failed to send maker earnings."
        );

        _transferHelper(
            actorFeeDistributionAddress,
            actorEarnings,
            "NeatFiProtocolOperationsUpgradeable::_claimDutchAuction: failed to actor earnings."
        );

        _transferHelper(
            protocolTreasury,
            netProtocolFee,
            "NeatFiProtocolOperationsUpgradeable::_claimDutchAuction: failed to send protocol fee."
        );

        IAssetAuction(auctionModule).claimAuction(bidder, orderHash, data);
    }

    /**
     * @dev An internal function to retrieve the address of the last bidder
     *      for an Auction Order (English/Dutch).
     * @param actorAddress - The address of the Actor contract.
     * @param orderHash - The hash of the Order.
     * @return lastBidder - The address of the last bidder.
     */
    function _getLastBidderAddress(address actorAddress, bytes32 orderHash)
        internal
        view
        returns (address lastBidder)
    {
        require(_isValidActorKey(actorAddress, orderHash));

        return IAssetAuction(auctionModule).getLastBidderAddress(orderHash);
    }

    /** Initializers */

    function __NeatFiProtocolOperations_init(
        address newSwapModule,
        address newSellModule,
        address newAuctionModule,
        address newPaymentsResolver,
        address newProtocolSettings,
        address newProtocolStorage,
        address newActorFactory,
        address payable newProtocolTreasury
    ) internal initializer {
        __AssetStructs_init();
        __AssetEnums_init();
        __RoleConstants_init();
        __AccessControl_init();

        _setSwapModule(newSwapModule);
        _setSellModule(newSellModule);
        _setAuctionModule(newAuctionModule);
        _setPaymentsResolver(newPaymentsResolver);
        _setProtocolSettings(newProtocolSettings);
        _setProtocolStorage(newProtocolStorage);
        _setActorFactory(newActorFactory);
        _setProtocolTreasury(newProtocolTreasury);
    }
}
