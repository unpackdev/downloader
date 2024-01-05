pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./NFT.sol";
import "./ICollectionManager.sol";

address constant ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
uint256 constant PRICE_CHANGE_DENOMINATOR = 10000;

struct Series {
    uint256 id;
    uint256 limit;
    uint256 minted;
    uint256 initialPrice;
    int256 priceChange;
    // Only set in `getCollections`.
    uint256 currentPrice;
    uint256 nextPrice;
}

struct Collection {
    uint256 id;
    string title;
    string uriBase;
    uint256 priceChangeTime;
    uint256 initialTimestamp;
    uint256 seriesCount;
    address paymentToken;
    mapping(uint256 => Series) series;
}

struct CollectionFlat {
    uint256 id;
    string title;
    string uriBase;
    uint256 priceChangeTime;
    uint256 initialTimestamp;
    address paymentToken;
    Series[] series;
}

contract Redeem is Ownable, CollectionManager, ReentrancyGuard {
    using Strings for uint256;

    mapping(uint256 => Collection) collections;
    uint256[] public collectionIds;

    NFT public nft;

    constructor(NFT nft_) {
        nft = nft_;
    }

    function startCollectionSale(uint256 collectionId) public onlyOwner {
        require(
            collections[collectionId].initialTimestamp == 0,
            "SALE_ALREADY_STARTED"
        );
        collections[collectionId].initialTimestamp = block.timestamp;
    }

    function updateCollectionUriBase(
        uint256 collectionId,
        string memory uriBase
    ) public onlyOwner {
        collections[collectionId].uriBase = uriBase;
    }

    function updateCollectionTitle(uint256 collectionId, string memory title)
        public
        onlyOwner
    {
        collections[collectionId].title = title;
    }

    function createCollection(
        string memory name,
        string memory uriBase,
        address paymentToken,
        uint256 priceChangeTime,
        uint256[] memory initialPrices,
        uint256[] memory limits,
        int256[] memory priceChanges
    ) public onlyOwner {
        uint256 collectionId = nft.nextAvailableCollectionId();
        nft.createCollection(collectionId);
        collectionIds.push(collectionId);

        collections[collectionId].id = collectionId;
        collections[collectionId].seriesCount = limits.length;
        collections[collectionId].title = name;
        collections[collectionId].uriBase = uriBase;
        collections[collectionId].priceChangeTime = priceChangeTime;
        collections[collectionId].paymentToken = paymentToken;

        require(limits.length == initialPrices.length, "INVALID_PARAMS_LENGTH");
        require(
            priceChanges.length == initialPrices.length,
            "INVALID_PARAMS_LENGTH"
        );

        for (uint256 i = 0; i < limits.length; i++) {
            Series memory series =
                Series({
                    id: i,
                    limit: limits[i],
                    initialPrice: initialPrices[i],
                    priceChange: priceChanges[i],
                    minted: 0,
                    currentPrice: 0,
                    nextPrice: 0
                });
            collections[collectionId].series[i] = series;
        }
    }

    function getCollections() external view returns (CollectionFlat[] memory) {
        uint256 collectionCount = collectionIds.length;
        CollectionFlat[] memory collectionsFlat =
            new CollectionFlat[](collectionCount);

        for (uint256 i = 0; i < collectionCount; i++) {
            uint256 collectionId = collectionIds[i];
            Collection storage collection = collections[collectionId];
            Series[] memory series = new Series[](collection.seriesCount);
            for (uint256 j = 0; j < collection.seriesCount; j++) {
                series[j] = collection.series[j];
                series[j].currentPrice = currentPrice(collectionId, j);
                series[j].nextPrice = calculateFuturePrice(collectionId, j, 1);
            }
            collectionsFlat[i] = CollectionFlat({
                id: collection.id,
                series: series,
                title: collection.title,
                uriBase: collection.uriBase,
                priceChangeTime: collection.priceChangeTime,
                initialTimestamp: collection.initialTimestamp,
                paymentToken: collection.paymentToken
            });
        }

        return collectionsFlat;
    }

    function currentPrice(uint256 collectionId, uint256 seriesId)
        public
        view
        returns (uint256)
    {
        return calculateFuturePrice(collectionId, seriesId, 0);
    }

    function calculateFuturePrice(
        uint256 collectionId,
        uint256 seriesId,
        uint256 periods
    ) public view returns (uint256) {
        uint256 price = collections[collectionId].series[seriesId].initialPrice;
        uint256 priceChangeTime = collections[collectionId].priceChangeTime;
        int256 priceChange =
            collections[collectionId].series[seriesId].priceChange;
        uint256 initialTimestamp = collections[collectionId].initialTimestamp;
        if (initialTimestamp == 0) {
            initialTimestamp = block.timestamp;
        }

        uint256 timePassed =
            ((block.timestamp - initialTimestamp) / priceChangeTime) + periods;

        for (uint256 i = 0; i < timePassed; i++) {
            if (priceChange >= 0) {
                price +=
                    (price * uint256(priceChange)) /
                    PRICE_CHANGE_DENOMINATOR;
            } else {
                price -=
                    (price * uint256(-priceChange)) /
                    PRICE_CHANGE_DENOMINATOR;
            }
        }

        return price;
    }

    function redeem(
        uint256 collectionId,
        uint256 seriesId,
        uint256 amount
    ) public payable nonReentrant {
        require(
            collections[collectionId].initialTimestamp > 0,
            "SALE_NOT_STARTED"
        );
        require(seriesId < collections[collectionId].seriesCount, "INVALID_ID");
        uint256 limit = collections[collectionId].series[seriesId].limit;
        uint256 edition = collections[collectionId].series[seriesId].minted;
        if (limit != 0) {
            require(edition + amount <= limit, "LIMIT_REACHED");
        }
        collections[collectionId].series[seriesId].minted = edition + amount;

        uint256 price = currentPrice(collectionId, seriesId);
        uint256 cost = price * amount;

        takePayment(collections[collectionId].paymentToken, cost);

        for (uint256 i = 0; i < amount; i++) {
            nft.mint(msg.sender, collectionId, seriesId, edition + i);
        }
    }

    function takePayment(address paymentToken, uint256 amount) internal {
        if (paymentToken == ETHEREUM) {
            require(msg.value >= amount, "INSUFFICIENT_ETH_AMOUNT");
            // Refund change.
            payable(msg.sender).transfer(msg.value - amount);
        } else {
            IERC20(paymentToken).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
    }

    function withdraw(address token) public onlyOwner {
        if (token == ETHEREUM) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 collectionId = nft.extractCollectionId(tokenId);
        uint256 seriesId = nft.extractSeriesId(tokenId);
        uint256 edition = nft.extractEdition(tokenId);

        string memory uriBase = collections[collectionId].uriBase;

        return
            string(
                abi.encodePacked(
                    uriBase,
                    "/",
                    (seriesId + 1).toString(),
                    "/",
                    (edition + 1).toString(),
                    ".json"
                )
            );
    }
}
