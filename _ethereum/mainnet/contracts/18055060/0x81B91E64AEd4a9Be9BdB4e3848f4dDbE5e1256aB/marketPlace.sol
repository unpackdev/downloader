//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./coBatch.sol";

contract NFTMarket is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter public _itemIds;
    Counters.Counter public _itemsSold;
    address public napaToken;
    address public usdtToken;
    CoBatchingPool public coBatchingPool;
    uint256 public minListPrice;

    constructor(
        address _napaToken,
        address _usdtToken,
        address payable _coBatchingPool,
        address payable _feesAddress,
        uint256 _minListPrice,
        uint256 _listingPercentage
    ) {
        napaToken = _napaToken;
        usdtToken = _usdtToken;
        coBatchingPool = CoBatchingPool(_coBatchingPool);
        feesAddress = _feesAddress;
        minListPrice = _minListPrice;
        feesPercentage = _listingPercentage;
    }

    function setAddresses(
        address _napaToken,
        address _usdtToken,
        address payable _coBatchingPool,
        address payable _feesAddress
    ) public onlyOwner {
        napaToken = _napaToken;
        usdtToken = _usdtToken;
        coBatchingPool = CoBatchingPool(_coBatchingPool);
        feesAddress = _feesAddress;
    }

    //fees structure starts
    address payable feesAddress;
    uint256 public feesPercentage = 0;

    // set Fees Percentage like this(
    // if you want "5" percentage Fees then add "500"
    // if you want "0.5" percentage Fees then add "50"
    // you can't set lower than 0.1 %
    // )
    function changeFeesPercentage(uint256 _newPercentage) public onlyOwner {
        require(
            _newPercentage >= 10,
            "value for new Fees Percentage should atleast be '10' equivalent to 0.10"
        );
        feesPercentage = _newPercentage;
    }

    function changeFeesAddress(address payable _feesAddress) public onlyOwner {
        feesAddress = _feesAddress;
    }

    function changeMinListPrice(uint256 _minListPrice) public onlyOwner {
        minListPrice = _minListPrice;
    }

    function getFeesAddress() public view returns (address _feesAddress) {
        _feesAddress = feesAddress;
    }

    //fees structure ends

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        PaymentMode paymentMode,
        bool isCobatchable,
        bool sold
    );
    event Received(address, uint256);

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        PaymentMode paymentMode;
        bool isCobatchable;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idMarketItem;

    function fetchSingleMarketItem(uint256 _id)
        public
        view
        returns (
            uint256 _nftId,
            address _nftAddress,
            uint256 _price,
            PaymentMode _paymentMode,
            bool _isCobatchable,
            address _seller
        )
    {
        _nftId = idMarketItem[_id].tokenId;
        _nftAddress = idMarketItem[_id].nftContract;
        _price = idMarketItem[_id].price;
        _paymentMode = idMarketItem[_id].paymentMode;
        _isCobatchable = idMarketItem[_id].isCobatchable;
        _seller = idMarketItem[_id].seller;
    }

    function setSale(
        uint256 tokenId,
        uint256 price,
        address nftContract,
        PaymentMode _paymentMode,
        bool _isCobatchable
    ) public nonReentrant {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        require(
            price >= minListPrice,
            "price of an Item should be at greater than or equals to minimum listing price"
        );
        idMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            _paymentMode,
            _isCobatchable,
            false
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(this),
            price,
            _paymentMode,
            _isCobatchable,
            false
        );
    }

    function claimBack(uint256 _itemId) public returns (bool) {
        MarketItem storage marketItem = idMarketItem[_itemId];
        require(
            marketItem.sold == false,
            "Item already sold, can't be claimed back"
        );
        require(
            marketItem.seller == msg.sender,
            "You're not the seller of this Item"
        );
        require(
            marketItem.owner == address(this),
            "MarketPlace doesn't have this Item"
        );
        marketItem.seller = payable(msg.sender);
        marketItem.owner = payable(msg.sender);
        marketItem.price = 0;

        IERC721(marketItem.nftContract).transferFrom(
            address(this),
            msg.sender,
            marketItem.tokenId
        );
        return true;
    }

    function buyNFTToken(uint256 itemId) public payable nonReentrant {
        uint256 _itemId = itemId;
        address nftContract = idMarketItem[_itemId].nftContract;
        uint256 poolId = coBatchingPool.returnPoolId(_itemId);
        PaymentMode paymentMode = idMarketItem[_itemId].paymentMode;

        require(
            IERC721(idMarketItem[_itemId].nftContract).ownerOf(
                idMarketItem[_itemId].tokenId
            ) == address(this),
            "either This Item is sold or not listed yet"
        );

        // (M -> M) and (M -> 1)
        // to buy a Co-batched NFT by (1. Co-batch or 2. Single buy)
        if (coBatchingPool.resalePoolInfo(_itemId) == true) {
            buyCoBatchOfCoBatch(_itemId);
        }
        // (1 -> M)
        // to buy NFT by (1. Co-batch)
        else if (coBatchingPool.activepool(poolId) == true) {
            buyCoBatch(_itemId);
        }
        // (1 -> 1)
        // to buy a single NFT Single buy
        else {
            uint256 tokenId = idMarketItem[_itemId].tokenId;
            IERC721(nftContract).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
            idMarketItem[_itemId].owner = payable(msg.sender);
            idMarketItem[_itemId].sold = true;
            _itemsSold.increment();
            // charging Fees in percentage
            if (feesPercentage >= 10) {
                uint256 fractionPrice = (((idMarketItem[_itemId].price) *
                    feesPercentage) / 100) / 100;
                if (paymentMode == PaymentMode.napaToken) {
                    // charging only half of percentage if item listed for NAPA tokens
                    feeTransfer(
                        msg.sender,
                        feesAddress,
                        paymentMode,
                        (fractionPrice / 2)
                    );
                } else {
                    feeTransfer(
                        msg.sender,
                        feesAddress,
                        paymentMode,
                        fractionPrice
                    );
                }
                feeTransfer(
                    msg.sender,
                    idMarketItem[_itemId].seller,
                    paymentMode,
                    idMarketItem[_itemId].price
                );
            } else {
                feeTransfer(
                    msg.sender,
                    idMarketItem[_itemId].seller,
                    paymentMode,
                    idMarketItem[_itemId].price
                );
            }
        }
    }

    // (1 -> M)
    //1) buy 1(single item) by Co-Batching
    function buyCoBatch(uint256 _itemId) internal {
        uint256 tokenId = idMarketItem[_itemId].tokenId;
        uint256 price = idMarketItem[_itemId].price;
        uint256 poolId = coBatchingPool.returnPoolId(_itemId);
        address nftContract = idMarketItem[_itemId].nftContract;
        (
            PoolBasicData memory _basicData,
            PoolMetadata memory _poolMetadata
        ) = coBatchingPool.fetchSinglePoolData(poolId);
        require(
            _poolMetadata.neededContribution == 0,
            "Pool contribution is not fullfilled yet"
        );
        require(
            _basicData.admin == msg.sender,
            "You are not a creator of this pool"
        );
        PaymentMode _paymentMode = idMarketItem[_itemId].paymentMode;
        IERC721(nftContract).transferFrom(
            address(this),
            address(coBatchingPool),
            tokenId
        );
        idMarketItem[_itemId].owner = payable(coBatchingPool);
        idMarketItem[_itemId].sold = true;
        _itemsSold.increment();

        feeTransferFromMarketPlace(
            idMarketItem[_itemId].seller,
            _paymentMode,
            price
        );
        coBatchingPool.setsellData(_itemId, poolId);
    }

    // (M -> M) and (M -> 1)
    //2) buy Co-Batch item -> by Two Ways(single or Co-Batch way)
    function buyCoBatchOfCoBatch(uint256 _itemId) internal {
        // to buy a Co-batched NFT by (1. Co-batch or 2. Single buy)
        uint256 tokenId = idMarketItem[_itemId].tokenId;
        uint256 poolId = coBatchingPool.returnPoolId(_itemId);
        address nftContract = idMarketItem[_itemId].nftContract;
        (PoolBasicData memory _basicData, ) = coBatchingPool
            .fetchSinglePoolData(poolId);
        //(M -> M)
        // to buy a Co-batched NFT by (1. Co-batch)
        if (
            _basicData.admin == msg.sender &&
            _basicData.poolMetadata.active == true
        ) {
            buyCoBatchByMore(_itemId, poolId, nftContract, tokenId);
        }
        // (M -> 1)
        // to buy a Co-batched NFT by (1. Single buy)
        else {
            buyCoBatchBySingle(_itemId);
        }
    }

    // (M -> M)
    //2.1) buy Co-Batch item -> by Co-Batching
    function buyCoBatchByMore(
        uint256 _itemId,
        uint256 poolId,
        address nftContract,
        uint256 tokenId
    ) internal {
        PaymentMode paymentMode = idMarketItem[_itemId].paymentMode;
        (uint256 newPoolId, address[] memory member) = coBatchingPool.newPoolId(
            _itemId
        );
        uint256 memberlength = member.length;
        IERC721(nftContract).transferFrom(
            address(this),
            address(coBatchingPool),
            tokenId
        );
        for (uint256 i = 0; i < memberlength; i++) {
            uint256 totalPerscentage = coBatchingPool.memberPercentage(
                newPoolId,
                member[i]
            );
            uint256 membertoken = ((idMarketItem[_itemId].price *
                totalPerscentage) / 100);
            feeTransferFromMarketPlace(member[i], paymentMode, membertoken);
        }
        idMarketItem[_itemId].owner = payable(coBatchingPool);
        idMarketItem[_itemId].sold = true;
        _itemsSold.increment();
        coBatchingPool.setData(_itemId, poolId);
    }

    // (M -> 1)
    //2.2) buy Co-Batch item -> by (1. Single buy)
    function buyCoBatchBySingle(uint256 _itemId) internal {
        uint256 tokenId = idMarketItem[_itemId].tokenId;
        PaymentMode paymentMode = idMarketItem[_itemId].paymentMode;
        (uint256 newPoolId, address[] memory member) = coBatchingPool.newPoolId(
            _itemId
        );
        uint256 memberlength = member.length;
        address nftContract = idMarketItem[_itemId].nftContract;
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        {
            for (uint256 i = 0; i < memberlength; i++) {
                uint256 totalPerscentage = coBatchingPool.memberPercentage(
                    newPoolId,
                    member[i]
                );
                uint256 membertoken = ((idMarketItem[_itemId].price *
                    totalPerscentage) / 100);
                feeTransfer(msg.sender, member[i], paymentMode, membertoken);
            }
        }
        idMarketItem[_itemId].owner = payable(msg.sender);
        idMarketItem[_itemId].sold = true;
        _itemsSold.increment();
        coBatchingPool.setResaleValue(_itemId);
    }

    function feeTransferFromMarketPlace(
        address _to,
        PaymentMode paymentMode,
        uint256 _amount
    ) internal returns (bool _res) {
        if (paymentMode == PaymentMode.napaToken) {
            IERC20(napaToken).transfer(_to, _amount);
        } else if (paymentMode == PaymentMode.usdtToken) {
            IERC20(usdtToken).transfer(_to, _amount);
        } else {
            payable(_to).transfer(_amount);
        }
        _res = true;
    }

    function feeTransfer(
        address _from,
        address _to,
        PaymentMode paymentMode,
        uint256 _amount
    ) internal returns (bool _res) {
        if (paymentMode == PaymentMode.napaToken) {
            require(
                IERC20(napaToken).allowance(_from, address(this)) >= _amount,
                "Insufficient NAPA Allowance"
            );
            IERC20(napaToken).transferFrom(_from, _to, _amount);
        } else if (paymentMode == PaymentMode.usdtToken) {
            require(
                IERC20(usdtToken).allowance(_from, address(this)) >= _amount,
                "Insufficient USDT Allowance"
            );
            IERC20(usdtToken).transferFrom(_from, _to, _amount);
        } else {
            require(_amount <= msg.value, "Please send sufficient ETH");
            payable(_to).transfer(_amount);
        }
        _res = true;
    }

    function reSellToken(
        uint256 itemId,
        uint256 price,
        PaymentMode _paymentMode,
        bool _isCobatchable
    ) public {
        require(
            price >= minListPrice,
            "price of an Item should be at greater than or equals to minimum listing price"
        );
        // by CoBatching Relist
        if (idMarketItem[itemId].owner == address(coBatchingPool)) {
            uint256 poolId = coBatchingPool.returnPoolId(itemId);
            (uint256 newprice, bool active) = coBatchingPool.isResaleActive(
                poolId
            );
            require(active == true, "Your Pool is not Active For Re-sale");
            address nftContract = idMarketItem[itemId].nftContract;
            uint256 tokenid = idMarketItem[itemId].tokenId;

            idMarketItem[itemId].sold = false;
            idMarketItem[itemId].price = newprice;
            idMarketItem[itemId].seller = payable(coBatchingPool);
            idMarketItem[itemId].owner = payable(address(this));
            idMarketItem[itemId].paymentMode = _paymentMode;
            idMarketItem[itemId].isCobatchable = _isCobatchable;

            coBatchingPool.transferNFT(address(this), tokenid, nftContract);
            _itemsSold.decrement();
        }
        // by Normal Relist
        else {
            require(
                idMarketItem[itemId].owner == msg.sender,
                "only item owner this operation"
            );
            address nftContract = idMarketItem[itemId].nftContract;
            uint256 tokenid = idMarketItem[itemId].tokenId;

            idMarketItem[itemId].sold = false;
            idMarketItem[itemId].price = price;
            idMarketItem[itemId].seller = payable(msg.sender);
            idMarketItem[itemId].owner = payable(address(this));
            idMarketItem[itemId].paymentMode = _paymentMode;
            idMarketItem[itemId].isCobatchable = _isCobatchable;

            _itemsSold.decrement();
            IERC721(nftContract).transferFrom(
                msg.sender,
                address(this),
                tokenid
            );
        }
    }

    function _endPool(uint256 itemId) public {
        uint256 poolId = coBatchingPool.returnPoolId(itemId);
        (
            PoolBasicData memory _basicData,
            PoolMetadata memory _poolMetadata
        ) = coBatchingPool.fetchSinglePoolData(poolId);
        require(_poolMetadata.active, "Pool Is not active");
        require(_basicData.admin == msg.sender, "You're not a Pool admin");
        uint256 returnPrice = _poolMetadata.floorPrice -
            _poolMetadata.neededContribution;

        PaymentMode paymentMode = idMarketItem[itemId].paymentMode;

        bool success = feeTransferFromMarketPlace(
            payable(coBatchingPool),
            paymentMode,
            returnPrice
        );

        if (success) {
            coBatchingPool.endPool(poolId, itemId);
        } else {
            require(false, "Sending funds to Co-Batch Failed");
        }
    }

    function _fetchSingleMarketItem(uint256 _id)
        public
        view
        returns (MarketItem memory)
    {
        return idMarketItem[_id];
    }

    //unsold Items on MarketPlace
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //All Items on MarketPlace
    function fetchAllMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = idMarketItem[i + 1].itemId;
            MarketItem storage currentItem = idMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    //fetches all MarketPlace Items bought by the user
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();

        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //Listed Items by User
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // fetches CoBatch Items of user
    function fetchPoolItems() public view returns (MarketItem[] memory) {
        uint256 currentIndex = 0;
        uint256[] memory poolDetails = coBatchingPool.fetchPoolDetails(
            msg.sender
        );
        MarketItem[] memory items = new MarketItem[](poolDetails.length);
        for (uint256 i = 0; i < poolDetails.length; i++) {
            MarketItem storage currentItem = idMarketItem[poolDetails[i]];
            items[currentIndex] = currentItem;
            currentIndex++;
        }
        return (items);
    }

    //fetches all NFTs on CoBatchPool
    function fetchCoBatchNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();

        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].owner == address(coBatchingPool)) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].owner == address(coBatchingPool)) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function withDrawFunds(address _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
        IERC20(napaToken).transfer(_to, IERC20(napaToken).balanceOf(_to));
        IERC20(napaToken).transfer(_to, IERC20(usdtToken).balanceOf(_to));
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}