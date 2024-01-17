// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILooksRareExchange {
    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    /**
     *  @dev seller makes order, buyer takes order with eth.
     *      If msg.value < price, protocol will use weth to pay remains charge.
     *  @param takerBid buyer order
     *  @param makerAsk seller order
     */
    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;

    /**
     *  @dev seller makes order, buyer takes order with ERC20(include weth).
     *  @param takerBid buyer order
     *  @param makerAsk seller order
     */
    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external;

    /**
     *  @dev buyer makes offer, seller takes offer with ERC20(include weth).
     *  @param takerAsk seller order
     *  @param makerBid buyer order
     */
    function matchBidWithTakerAsk(
        TakerOrder calldata takerAsk,
        MakerOrder calldata makerBid
    ) external;
}

interface ITransferSelectorNFT {
    function checkTransferManagerForToken(address collection)
        external
        view
        returns (address);
}

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

interface IExecutionStrategy {
    function canExecuteTakerAsk(
        ILooksRareExchange.TakerOrder calldata takerAsk,
        ILooksRareExchange.MakerOrder calldata makerBid
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(
        ILooksRareExchange.TakerOrder calldata takerBid,
        ILooksRareExchange.MakerOrder calldata makerAsk
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}

interface ILooksRareAdapter {
    /**
     * @dev buyer takes order with eth.
     * @param takerOrders buyer orders
     * @param makerOrders seller orders
     * @param recipient The address to receive nfts & refunds.
     */
    function buyAssetsForEth(
        ILooksRareExchange.TakerOrder[] calldata takerOrders,
        ILooksRareExchange.MakerOrder[] calldata makerOrders,
        address recipient
    ) external payable;

    /**
     * @dev buyer takes order with ERC20.
     * @param takerOrders buyer orders
     * @param makerOrders seller orders
     * @param buyer The address to pay ERC20, receive nfts and refund.
     */
    function buyAssetForERC20(
        ILooksRareExchange.TakerOrder[] calldata takerOrders,
        ILooksRareExchange.MakerOrder[] calldata makerOrders,
        address buyer
    ) external;

    /**
     * @dev seller takes offer with ERC721.
     * @param takerOrders seller orders
     * @param makerOrders buyer orders
     * @param seller The address to pay ERC721, receive ERC20 and refund.
     */
    function takeOfferForERC20(
        ILooksRareExchange.TakerOrder[] calldata takerOrders,
        ILooksRareExchange.MakerOrder[] calldata makerOrders,
        address seller
    ) external;
}
