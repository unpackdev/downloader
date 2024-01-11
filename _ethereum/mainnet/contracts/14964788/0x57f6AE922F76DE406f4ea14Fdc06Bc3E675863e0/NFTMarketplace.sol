// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

interface IStake {
    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
        address owner;
        uint256 lockEndTimestamp;
        uint256 rewardMultiplier;
    }

    function getLevel(uint tokenId) external view returns(uint24 level);
    function stakeInfo(uint256 tokenId) external view returns (Stake memory);
}

contract marketplace is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemIds2;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsSold2;

    address public treasury;
    address public nftContractMain;
    address public token;
    uint public decimals;
    mapping(address => bool) authorizedSeller;
    address public stakeAddress;
    constructor(address token_, address stakeAddress_, uint decimals_, address nft, address treasury_) {
        nftContractMain = nft;
        token = token_;
        decimals = decimals_;
        stakeAddress = stakeAddress_;
        authorizedSeller[msg.sender] = true;
        treasury = treasury_;
    }

    function setTreasury(address account) external onlyOwner {
        treasury = account;
    }

    modifier onlyAuthorized() {
      require(authorizedSeller[msg.sender], "Not authorized");
      _;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        bool sold;
        string tokenURI;
        uint24 levelRequired;
    }
    
    struct MarketItem2 {
        uint256 itemId;
        address seller;
        uint256 price;
        uint256 stock;
        uint24 levelRequired;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(uint256 => MarketItem2) private idToMarketItem2;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event MarketItemCreated2(
        uint256 itemId,
        address seller,
        uint256 price,
        uint256 stock,
        uint24 levelRequired
    );

    event MarketItemSold(uint256 indexed itemId, address owner);

    function setStakeAddress(address newAddress) external onlyOwner {
        stakeAddress = newAddress;
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint24 minLevel
    ) external onlyAuthorized {
        require(price > 0, "Price must be greater than 0");
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price * 10 ** decimals,
            false,
            "",
            minLevel
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price * 10 ** decimals,
            false
        );
    }

    function createMarketItem2(
        uint256 price,
        uint stock,
        uint24 minLevel
    ) external onlyAuthorized returns(uint itemId) {
        require(price > 0, "Price must be greater than 0");
        _itemIds2.increment();
        itemId = _itemIds2.current();

        idToMarketItem2[itemId] = MarketItem2(
            itemId,
            msg.sender,
            price * 10 ** decimals,
            stock,
            minLevel
        );

        emit MarketItemCreated2(
            itemId,
            msg.sender,
            price * 10 ** decimals,
            stock,
            minLevel
        );
    }

    function refillStock(uint256 itemId, uint amount) external onlyOwner {
        if (idToMarketItem2[itemId].stock == 0) _itemsSold2.decrement();
        idToMarketItem2[itemId].stock += amount;
    }

    function buyItem(address nftContract, uint256 itemId, uint tokenId)
        external
    {
        if (IERC721(nftContractMain).ownerOf(tokenId) != msg.sender) {
            require(IStake(stakeAddress).stakeInfo(tokenId).owner == msg.sender, "Not yours");
        }
        require(IStake(stakeAddress).getLevel(tokenId) >= idToMarketItem[itemId].levelRequired,"Earn more xp to be able to buy this item");
        require(!idToMarketItem[itemId].sold, "Already sold");
        IERC20(token).transferFrom(msg.sender, treasury, idToMarketItem[itemId].price);
        
        IERC721(nftContract).transferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId);
        idToMarketItem[itemId].owner = msg.sender;
        _itemsSold.increment();
        idToMarketItem[itemId].sold = true;
        emit MarketItemSold(itemId, msg.sender);
    }

    function buyItem2(uint256 itemId, uint amount, uint tokenId)
        external
    {
        if (IERC721(nftContractMain).ownerOf(tokenId) != msg.sender) {
            require(IStake(stakeAddress).stakeInfo(tokenId).owner == msg.sender, "Not yours");
        }
        require(IStake(stakeAddress).getLevel(tokenId) >= idToMarketItem2[itemId].levelRequired,"Earn more xp to be able to buy this item");

        require(idToMarketItem2[itemId].stock >= amount, "Not enough left");
        IERC20(token).transferFrom(msg.sender, treasury, idToMarketItem2[itemId].price);
        idToMarketItem2[itemId].stock -= amount;
        if (idToMarketItem2[itemId].stock == 0) _itemsSold2.increment();
    }

    function delist(uint256 itemId)
        external onlyAuthorized
    {
        require(!idToMarketItem[itemId].sold, "Already sold");
        IERC721(idToMarketItem[itemId].nftContract).transferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId);
        idToMarketItem[itemId].owner = msg.sender;
        _itemsSold.increment();
        idToMarketItem[itemId].sold = true;
        emit MarketItemSold(itemId, msg.sender);
    }

    function delist2(uint256 itemId)
        external onlyAuthorized
    {
        require(idToMarketItem2[itemId].stock > 0, "Already sold out");
        
        idToMarketItem2[itemId].stock = 0;
        _itemsSold2.increment();
    }

    function fetchMarketItems() external view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketItem memory currentItem = idToMarketItem[currentId];
                currentItem.tokenURI = ERC721(currentItem.nftContract).tokenURI(currentItem.tokenId);
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMarketItems2() external view returns (MarketItem2[] memory) {
        uint256 itemCount = _itemIds2.current();
        uint256 unsoldItemCount = _itemIds2.current() - _itemsSold2.current();
        uint256 currentIndex;

        MarketItem2[] memory items = new MarketItem2[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem2[i + 1].stock > 0) {
                uint256 currentId = i + 1;
                MarketItem2 memory currentItem = idToMarketItem2[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function totalSold() external view returns (uint) {
      return _itemsSold.current();
    }

    function totalSold2() external view returns (uint) {
      return _itemsSold2.current();
    }

    function addSeller(address account) external onlyOwner {
      authorizedSeller[account] = true;
    }

    function removeSeller(address account) external onlyOwner {
      authorizedSeller[account] = false;
    }

    function ids() external view returns(uint){
        return _itemIds.current();
    }

    function ids2() external view returns(uint){
        return _itemIds2.current();
    }

    function fetchItem(uint id) external view returns (MarketItem memory) {
        return idToMarketItem[id];
    }

    function fetchItem2(uint id) external view returns (MarketItem2 memory) {
        return idToMarketItem2[id];
    }

    function isSeller(address a) external view returns (bool) {
        return authorizedSeller[a];
    }

    function claimOtherTokens(IERC20 tokenAddress, address walletAddress) external onlyOwner {
        require(walletAddress != address(0), "walletAddress can't be 0 address");
        SafeERC20.safeTransfer(tokenAddress, walletAddress, tokenAddress.balanceOf(address(this)));
    }

    function collectedTokens() external view returns(uint){
        return IERC20(token).balanceOf(address(this));
    }

    function claimTokens() external onlyOwner {
        SafeERC20.safeTransfer(IERC20(token), msg.sender, IERC20(token).balanceOf(address(this)));
    }

}
