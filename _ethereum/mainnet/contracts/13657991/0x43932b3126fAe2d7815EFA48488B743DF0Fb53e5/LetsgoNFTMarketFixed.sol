//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./LetsgoNFT.sol";
import "./LetsgoNFTBase.sol";

contract LetsgoNFTMarketFixed is ReentrancyGuard, Ownable, LetsgoNFTBase {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    uint256 private _platformFee = 250;
    bool private _disable = false;
    bytes4 _letsgoNftInterfaceId = 0xce77acc3;
    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(uint256 => AddreessWithPercent[]) private _affiliates;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
    }

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event MarketItemCancelled(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId
    );

      function listForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        AddreessWithPercent[] memory affiliates
    ) external payable nonReentrant {
        require(_disable == false, "listForSale: market is disabled");
        require(
            nftContract != address(0),
            "listForSale: nft contract address can't be empty"
        );
        require(tokenId > 0, "listForSale: tokenId must be higher than 0");
        require(price > 0, "listForSale: price must be at least 1 wei");
        this.validateAffiliates(affiliates);

        bool isLetsgoNftContract = LetsgoNFT(nftContract).supportsInterface(
            _letsgoNftInterfaceId
        );
        if (isLetsgoNftContract == true) {
            uint256 royalty = LetsgoNFT(nftContract).getRoyalty(tokenId);
            require(
                royalty <= mantissa / 2,
                "listForSale: royalty should be less or equal 50%"
            );
           
            AddreessWithPercent[] memory coCreators = LetsgoNFT(nftContract).getCoCreators(tokenId);
            this.validateCoCreators(coCreators);
        }

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price
        );

        for (uint256 i = 0; i < affiliates.length; i++) {
            _affiliates[itemId].push(affiliates[i]);
        }

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(itemId, nftContract, tokenId, msg.sender, price);
    }

    function purchase(address nftContract, uint256 itemId)
        external
        payable
        nonReentrant
    {
        require(
            nftContract != address(0),
            "purchase: nft contract address can't be empty"
        );
        require(itemId > 0, "purchase: itemId must be higher than 0");
        require(
            idToMarketItem[itemId].owner == address(0),
            "purchase: nft is not for sale"
        );

        bool isLetsgoNftContract = LetsgoNFT(nftContract).supportsInterface(
            _letsgoNftInterfaceId
        );

        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        uint256 royalty;
        AddreessWithPercent[] memory coCreators;
        AddreessWithPercent[] memory affiliates = _affiliates[itemId];
         this.validateAffiliates(affiliates);
        
        if (isLetsgoNftContract == true) {
            royalty = LetsgoNFT(nftContract).getRoyalty(tokenId);
            require(
                royalty <= mantissa / 2,
                "purchase: royalty should be less or equal 50%"
            );

            coCreators = LetsgoNFT(nftContract).getCoCreators(tokenId);
            this.validateCoCreators(coCreators);
        }

        require(
            msg.value == price,
            "purchase: Please submit the exact asking price in order to complete the purchase"
        );

        uint256 finalValue = msg.value;
        uint256 platformFeeValue = (finalValue * _platformFee) / mantissa;
        uint256 royaltyValue = (finalValue * royalty) / mantissa;
        finalValue = finalValue - platformFeeValue - royaltyValue;

        if (isLetsgoNftContract == true) {
            address payable nftCreator = payable(
                LetsgoNFT(nftContract).getCreator(tokenId)
            );

            if (royaltyValue > 0) {
                uint256 creatorValue = royaltyValue;
              
                for (uint256 i = 0; i < coCreators.length; i++) {
                    uint256 coCreatoralue = (royaltyValue * coCreators[i].value) / mantissa;  
                    creatorValue -= coCreatoralue;
                    address payable nftCoCreator = payable(coCreators[i].addr);
                    nftCoCreator.transfer(coCreatoralue);
                }
                nftCreator.transfer(creatorValue);
            }

            uint256 finalValueBuffer = finalValue;
            for (uint256 i = 0; i < affiliates.length; i++) {
                uint256 affiliateValue = (finalValueBuffer * affiliates[i].value) / mantissa;  
                finalValue -= affiliateValue;
                address payable nftAffiliate = payable(affiliates[i].addr);
                nftAffiliate.transfer(affiliateValue);
            }
        }

        idToMarketItem[itemId].seller.transfer(finalValue);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
    }

    function cancel(address nftContract, uint256 itemId) external nonReentrant {
        require(
            nftContract != address(0),
            "cancel: nft contract address can't be empty"
        );
        require(itemId > 0, "cancel: itemId must be higher than 0");

        address seller = idToMarketItem[itemId].seller;
        uint256 tokenId = idToMarketItem[itemId].tokenId;

        require(
            idToMarketItem[itemId].owner == address(0),
            "cancel: nft is not for sale"
        );

        require(
            seller == msg.sender || owner() == msg.sender,
            "cancel: only seller or owner can cancel"
        );

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        delete idToMarketItem[itemId];

        emit MarketItemCancelled(itemId, nftContract, tokenId);
    }

    function fetchItem(uint256 itemId)
        external
        view
        returns (MarketItem memory)
    {
        MarketItem memory item = idToMarketItem[itemId];
        return item;
    }

    function fetchItems(address addr)
        external
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount;
        uint256 currentIndex;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == addr) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == addr) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function setPlatformFee(uint256 fee) external onlyOwner {
        require(
            fee <= mantissa / 2,
            "setPlatformFee: fee should be less or equal to 50%"
        );
        _platformFee = fee;
    }

    function getPlatformFee() external view returns (uint256) {
        return _platformFee;
    }

    function withdrawalPlatformFee(address payable addr) external onlyOwner {
        require(
            addr != address(0),
            "withdrawalPlatformFee: address can't be empty"
        );
        addr.transfer(address(this).balance);
    }

    function setDisable(bool state) external onlyOwner {
        _disable = state;
    }
}
