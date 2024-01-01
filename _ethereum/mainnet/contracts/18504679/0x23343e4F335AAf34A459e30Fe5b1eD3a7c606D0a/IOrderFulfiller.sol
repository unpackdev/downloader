interface IOrderFulfiller {
    struct OrderParameters {
        address payable offerer;
        address receiver;
        OfferItem offerItem;
        RoyaltyData royalty;
        PendingAmountData pendingAmountsData;
        uint256 salt;
        bytes orderSignature;
        bytes pendingAmountsSignature;
        OfferTokenType tokenType;
    }

    // Order without pending amounts
    struct PureOrder { 
        address payable offerer;
        OfferItem offerItem;
        RoyaltyData royalty;
        uint256 salt;
    }

    struct OfferItem {
        address offerToken;
        uint256 offerTokenId;
        uint256 offerAmount; // the amount of ether for the offerer
        uint256 endTime; // offer expiration timestamp
        uint256 amount; // amount of items (erc1155)
    }

    struct RoyaltyData {
        uint256 royaltyPercent;
        address payable royaltyRecipient;
    }

    struct PendingAmountData {
        uint256 offererPendingAmount;
        uint256 buyerPendingAmount;
        bytes32 orderHash;
    }

    struct BatchOrderParameters {
        address payable offerer;
        address receiver;
        uint16 offererIndex; // index in the array of offerers
        OfferItem offerItem;
        RoyaltyData royalty;
        PendingAmountData pendingAmountsData;
        uint256 salt;
        bytes orderSignature;
        bytes pendingAmountsSignature;
        OfferTokenType tokenType;
    }

    struct OrderStatus {
        bool isFulfilled;
        bool isCancelled;
    }

    enum OfferTokenType {
        ERC721,
        ERC1155
    }

    event OrderFulfilled(
        address indexed offerer,
        address indexed receiver,
        address offerToken,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 tradeAmount,
        bytes32 orderHash
    );
    event OrderCancelled(
        address indexed offerer,
        address offerToken,
        uint256 tokenId,
        bytes32 orderHash
    );

    function fulfillOrder(OrderParameters memory parameters) external payable;

    function batchFulfillOrder(
        BatchOrderParameters[] memory parameters,
        address[] memory offerers
    ) external payable;
}