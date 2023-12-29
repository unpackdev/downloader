// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./marketPlace.sol";
//helpers to access Marketplace here
enum PaymentMode {
    napaToken,
    usdtToken,
    ethToken
}
//Fees setup ends
enum PoolType {
    Private,
    Public
}

struct PoolBasicData {
    address admin;
    uint256 itemId;
    uint256 nftId;
    address nftAddress;
    address owner;
    PoolMetadata poolMetadata;
}

struct PoolMetadata {
    uint256 maxParticipants;
    uint256 maxContribution;
    uint256 expirationTime;
    PoolType poolType;
    PaymentMode _paymentMode;
    uint256 floorPrice;
    uint256 neededContribution;
    bool active;
    uint256 resaleId;
}
struct resaleItemInfo {
    uint256 nftId;
    address nftcontract;
    uint256 newPrice;
    bool activeForSale;
}

contract CoBatchingPool is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public _poolId;
    // Counters.Counter public _itemIds;
    NFTMarket public _nftMarketPlace;
    IERC20 public napaToken;
    IERC20 public usdtToken;
    address MarketPlaceAddress;

    constructor(
        address _napaToken,
        address _usdtToken,
        address payable _feesAddress
    ) {
        napaToken = IERC20(_napaToken);
        usdtToken = IERC20(_usdtToken);
        feesAddress = _feesAddress;
    }

    //Fees setup starts
    address payable public feesAddress;

    function changeFeesAddress(address payable _feesAddress) public onlyOwner {
        feesAddress = _feesAddress;
    }

    //Fees setup ends

    struct Participant {
        address account;
        uint256 contribution;
        uint256 percentageOwns;
        bool voted;
    }

    struct fractionInfo {
        uint256 poolId;
        address seller;
        uint256 contributionPrice;
        bool sold;
    }

    struct itemInfo {
        uint256 poolId;
        bool isPoolCreated;
    }

    struct resaleitem {
        uint256 poolid;
        bool resalepoolitem;
    }
    struct marketPlaceItemData {
        uint256 nftId;
        address nftAddress;
        uint256 price;
        PaymentMode PaymentMode;
        bool isCobatchable;
        address seller;
    }

    mapping(uint256 => PoolBasicData) public pools;
    mapping(uint256 => mapping(address => Participant)) public participants;
    mapping(uint256 => mapping(uint256 => resaleItemInfo)) public resaleItem;
    mapping(uint256 => address[]) public participantList;
    mapping(uint256 => mapping(address => fractionInfo)) public fractionSeller;
    mapping(uint256 => itemInfo) public itempoolinfo;
    mapping(uint256 => resaleitem) public resalepooliteminfo;
    mapping(uint256 => mapping(address => bool)) public isPrivatePoolMember;
    mapping(uint256 => fractionInfo[]) public onSellFractions;

    event PoolCreated(
        uint256 indexed poolId,
        address indexed admin,
        uint256 indexed nftId,
        address nftContract,
        uint256 maxParticipants,
        uint256 maxContribution,
        uint256 expirationTime,
        PoolType poolType,
        uint256 floorPrice
    );

    event PoolJoined(
        uint256 indexed poolId,
        address indexed participant,
        uint256 contribution
    );

    event PoolEnded(uint256 indexed poolId, bool success);

    event PoolListed(uint256 indexed poolId, uint256 price);

    event VoteCast(
        uint256 indexed poolId,
        address indexed participant,
        bool accept
    );

    event Received(address, uint256);

    modifier onlyPoolAdmin(uint256 __poolId) {
        require(
            msg.sender == pools[__poolId].admin,
            "Only pool admin can call this function"
        );
        _;
    }

    modifier onlyPoolParticipant(uint256 __poolId) {
        require(
            participants[__poolId][msg.sender].account == msg.sender,
            "Only pool participant can call this function"
        );
        _;
    }

    function setMarketplaceaddress(address payable _marketPlaceAddress)
        public
        onlyOwner
    {
        MarketPlaceAddress = _marketPlaceAddress;
        _nftMarketPlace = NFTMarket(_marketPlaceAddress);
    }

    function changeTokens(address _napaToken, address _usdtToken)
        public
        onlyOwner
    {
        napaToken = IERC20(_napaToken);
        usdtToken = IERC20(_usdtToken);
    }

    function fetchMarketData(uint256 _id)
        public
        view
        returns (marketPlaceItemData memory _marketPlaceItemData)
    {
        (
            uint256 _nftId,
            address _nftAddress,
            uint256 _price,
            PaymentMode _paymentMode,
            bool _isCobatchable,
            address _seller
        ) = _nftMarketPlace.fetchSingleMarketItem(_id);

        _marketPlaceItemData.nftId = _nftId;
        _marketPlaceItemData.price = _price;
        _marketPlaceItemData.PaymentMode = _paymentMode;
        _marketPlaceItemData.nftAddress = _nftAddress;
        _marketPlaceItemData.isCobatchable = _isCobatchable;
        _marketPlaceItemData.seller = _seller;
    }

    function amountPayment(
        PaymentMode _paymentMode,
        uint256 _amount,
        address payable _to,
        bool _isFees
    ) internal returns (bool _res) {
        uint256 fees = (_amount).mul(20).div(100);
        if (_paymentMode == PaymentMode.napaToken) {
            if (_isFees) {
                napaToken.transferFrom(msg.sender, _to, fees);
            } else {
                napaToken.transferFrom(msg.sender, _to, _amount);
            }
        } else if (_paymentMode == PaymentMode.usdtToken) {
            if (_isFees) {
                usdtToken.transferFrom(msg.sender, _to, fees);
            } else {
                usdtToken.transferFrom(msg.sender, _to, _amount);
            }
        } else if (_paymentMode == PaymentMode.ethToken) {
            if (_isFees) {
                require(
                    fees <= msg.value,
                    "Please send sufficient ETH for Fees"
                );
                payable(_to).transfer(fees);
            } else {
                require(
                    _amount <= msg.value,
                    "Please send sufficient ETH for DownPayment/Fraction"
                );
                payable(_to).transfer(_amount);
            }
        }
        _res = true;
    }

    function feeTransferFromCoBatch(
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

    function addMembers(uint256 __poolId, address[] memory _members)
        public
        onlyPoolAdmin(__poolId)
        returns (bool)
    {
        for (uint256 i = 0; i < _members.length; i++) {
            isPrivatePoolMember[__poolId][_members[i]] = true;
        }
        return true;
    }

    function removeMembers(uint256 __poolId, address[] memory _members)
        public
        onlyPoolAdmin(__poolId)
        returns (bool)
    {
        for (uint256 i = 0; i < _members.length; i++) {
            isPrivatePoolMember[__poolId][_members[i]] = false;
        }
        return true;
    }

    function createPool(
        uint256 _itemId,
        uint256 _maxParticipants,
        uint256 _maxContribution,
        uint256 _biddingTime,
        PoolType _poolType
    ) public payable {
        marketPlaceItemData memory marketData = fetchMarketData(_itemId);
        uint256 itemPrice = marketData.price;
        require(marketData.isCobatchable, "this Item is not Co-Batchable");
        require(
            IERC721(marketData.nftAddress).ownerOf(marketData.nftId) ==
                address(MarketPlaceAddress),
            "either This NFT is sold or not listed on MarketPlace yet"
        );
        require(
            marketData.seller != msg.sender,
            "you cannot create a Pool for your own item"
        );
        _poolId.increment();
        uint256 poolId = _poolId.current();

        pools[poolId].poolMetadata = PoolMetadata(
            _maxParticipants,
            _maxContribution,
            block.timestamp + _biddingTime,
            _poolType,
            marketData.PaymentMode,
            itemPrice,
            itemPrice,
            true,
            0
        );

        pools[poolId] = PoolBasicData(
            msg.sender,
            _itemId,
            marketData.nftId,
            marketData.nftAddress,
            address(this),
            pools[poolId].poolMetadata
        );
        uint256 downPayment = (itemPrice).mul(10).div(100);
        // getting Down Payment Paid
        amountPayment(
            marketData.PaymentMode,
            downPayment,
            payable(MarketPlaceAddress),
            false
        );
        // getting Fees Payment Paid
        amountPayment(
            marketData.PaymentMode,
            downPayment,
            payable(feesAddress),
            true
        );

        pools[poolId].poolMetadata.neededContribution =
            pools[poolId].poolMetadata.neededContribution -
            downPayment;

        uint256 percentage = ((downPayment * 100) * 100) / (itemPrice * 100);

        participants[poolId][msg.sender] = Participant({
            account: msg.sender,
            contribution: downPayment,
            percentageOwns: percentage,
            voted: false
        });

        participantList[poolId].push(msg.sender);
        itempoolinfo[_itemId] = itemInfo(poolId, true);

        emit PoolJoined(poolId, msg.sender, downPayment);

        emit PoolCreated(
            poolId,
            msg.sender,
            marketData.nftId,
            marketData.nftAddress,
            _maxParticipants,
            _maxContribution,
            block.timestamp + _biddingTime,
            _poolType,
            itemPrice
        );
    }

    function joinPool(uint256 __poolId, uint256 _amount) public payable {
        uint256 amt = _amount;
        PoolBasicData storage pool = pools[__poolId];
        require(pool.poolMetadata.active, "Pool is not active");
        require(
            block.timestamp <= pool.poolMetadata.expirationTime,
            "Pool has expired"
        );
        require(
            participants[__poolId][msg.sender].account != msg.sender,
            "You have already joined this pool"
        );
        require(
            participantList[__poolId].length <
                pool.poolMetadata.maxParticipants,
            "Pool is full"
        );
        if (pool.poolMetadata.poolType == PoolType.Private) {
            require(
                isPrivatePoolMember[__poolId][msg.sender],
                "This Pool is Private and You're not allowed by the Admin to Join this Pool"
            );
        }
        require(
            amt <= pool.poolMetadata.maxContribution,
            "Amount should not be greater than the actual contribution amount"
        );
        require(
            amt <= pool.poolMetadata.neededContribution,
            "please transfer needed token or Contribution is fulfilled"
        );

        // uint256 percentage = ((downPayment * 100) * 100) / (itemPrice * 100);

        uint256 percentage = ((amt * 100) * 100) /
            (pools[__poolId].poolMetadata.floorPrice * 100);

        amountPayment(
            pools[__poolId].poolMetadata._paymentMode,
            amt,
            payable(MarketPlaceAddress),
            false
        );

        pool.poolMetadata.neededContribution =
            pool.poolMetadata.neededContribution -
            amt;
        participants[__poolId][msg.sender] = Participant({
            account: msg.sender,
            contribution: amt,
            percentageOwns: percentage,
            voted: false
        });
        participantList[__poolId].push(msg.sender);
        emit PoolJoined(__poolId, msg.sender, amt);
    }

    function endPool(uint256 __poolId, uint256 _itemId) public {
        require(
            msg.sender == MarketPlaceAddress,
            "Only MarketPlace can call this function"
        );
        PoolBasicData storage pool = pools[__poolId];
        require(pool.poolMetadata.active, "Pool is not active");
        for (uint256 i = 0; i < participantList[__poolId].length; i++) {
            address participant = participantList[__poolId][i];
            feeTransferFromCoBatch(
                participant,
                pool.poolMetadata._paymentMode,
                participants[__poolId][participant].contribution
            );
        }
        pools[__poolId].poolMetadata.active = false;
        itempoolinfo[_itemId].isPoolCreated = false;
        emit PoolEnded(__poolId, false);
    }

    function reListItem(uint256 __poolId, uint256 _newPrice)
        public
        onlyPoolAdmin(__poolId)
    {
        require(
            _newPrice >= _nftMarketPlace.minListPrice(),
            "price of an Item should be at greater than or equals to minimum listing price"
        );
        PoolBasicData storage pool = pools[__poolId];
        marketPlaceItemData memory marketData = fetchMarketData(pool.itemId);
        require(!pool.poolMetadata.active, "Pool is active");
        require(
            IERC721(marketData.nftAddress).ownerOf(marketData.nftId) ==
                address(this),
            "You must own the NFT to resale"
        );
        pool.poolMetadata.resaleId++;
        uint256 resaleid = pool.poolMetadata.resaleId;

        resaleItem[__poolId][resaleid] = resaleItemInfo(
            marketData.nftId,
            marketData.nftAddress,
            _newPrice,
            false
        );
    }

    function voteForPrice(uint256 __poolId, bool _accept)
        public
        onlyPoolParticipant(__poolId)
    {
        PoolBasicData storage pool = pools[__poolId];

        require(pool.poolMetadata.active == false, "pool is active");

        require(
            !participants[__poolId][msg.sender].voted,
            "You have already voted"
        );
        participants[__poolId][msg.sender].voted = _accept;

        if (votingResult(__poolId) > 50) {
            uint256 resaleid = pool.poolMetadata.resaleId;
            resaleItem[__poolId][resaleid].activeForSale = true;
        }
        emit VoteCast(__poolId, msg.sender, _accept);
    }

    function votingResult(uint256 __poolId) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < participantList[__poolId].length; i++) {
            address participant = participantList[__poolId][i];
            if (participants[__poolId][participant].voted == true) {
                count++;
            }
        }
        uint256 voteResult = (count * 100) / participantList[__poolId].length;
        return voteResult;
    }

    function sellFraction(uint256 __poolId)
        public
        onlyPoolParticipant(__poolId)
    {
        PoolBasicData storage pool = pools[__poolId];
        require(pools[__poolId].poolMetadata.active, "Pool is not active");
        require(
            block.timestamp <= pool.poolMetadata.expirationTime,
            "Pool has expired"
        );
        fractionInfo memory _fractionInfo = fractionInfo(
            __poolId,
            msg.sender,
            participants[__poolId][msg.sender].contribution,
            false
        );
        fractionSeller[__poolId][msg.sender] = _fractionInfo;
        onSellFractions[__poolId].push(_fractionInfo);
    }

    function BuyFraction(uint256 __poolId, uint256 _fractionIndex)
        public
        payable
    {
        PoolBasicData storage pool = pools[__poolId];
        fractionInfo memory _fractionDetails = onSellFractions[__poolId][
            _fractionIndex
        ];
        uint256 amt = _fractionDetails.contributionPrice;
        require(pools[__poolId].poolMetadata.active, "Pool is not active");
        require(
            block.timestamp <= pool.poolMetadata.expirationTime,
            "Pool has expired"
        );
        require(
            fractionSeller[__poolId][_fractionDetails.seller].sold == false,
            "fraction already sold"
        );
        require(
            participants[__poolId][_fractionDetails.seller].contribution ==
                amt ||
                participants[__poolId][_fractionDetails.seller].contribution ==
                msg.value,
            "Amount not match"
        );
        uint256 percentage = participants[__poolId][_fractionDetails.seller]
            .percentageOwns;
        address seller = participants[__poolId][_fractionDetails.seller]
            .account;
        amountPayment(
            pools[__poolId].poolMetadata._paymentMode,
            amt,
            payable(seller),
            false
        );

        for (uint256 i = 0; i < participantList[__poolId].length; i++) {
            address participant = participantList[__poolId][i];
            if (participant == seller) {
                participantList[__poolId][i] = msg.sender;
                break;
            }
        }
        delete participants[__poolId][_fractionDetails.seller];
        if (_fractionDetails.seller == pools[__poolId].admin) {
            pools[__poolId].admin = msg.sender;
        }
        participants[__poolId][msg.sender] = Participant(
            msg.sender,
            amt,
            percentage,
            false
        );
        onSellFractions[__poolId][_fractionIndex].sold = true;
        fractionSeller[__poolId][seller].sold = true;
    }

    function returnPoolId(uint256 _itemId)
        public
        view
        returns (uint256 poolId)
    {
        poolId = itempoolinfo[_itemId].poolId;
    }

    function resalePoolInfo(uint256 _itemId) public view returns (bool) {
        bool data = resalepooliteminfo[_itemId].resalepoolitem;
        return data;
    }

    function newPoolId(uint256 _itemId)
        public
        view
        returns (uint256, address[] memory)
    {
        uint256 __poolId = resalepooliteminfo[_itemId].poolid;
        address[] memory member = participantList[__poolId];
        return (__poolId, member);
    }

    function memberPercentage(uint256 _poolid, address _member)
        public
        view
        returns (uint256)
    {
        uint256 percentage = participants[_poolid][_member].percentageOwns;
        return percentage;
    }

    function setData(uint256 _itemId, uint256 _poolid) public {
        resalepooliteminfo[_itemId].resalepoolitem = false;
        pools[_poolid].poolMetadata.active = false;
        itempoolinfo[_itemId].isPoolCreated = false;
        resalepooliteminfo[_itemId] = resaleitem(_poolid, true);
    }

    function setsellData(uint256 _itemId, uint256 _poolid) public {
        pools[_poolid].poolMetadata.active = false;
        itempoolinfo[_itemId].isPoolCreated = false;
        resalepooliteminfo[_itemId] = resaleitem(_poolid, true);
    }

    function setResaleValue(uint256 _itemId) public {
        resalepooliteminfo[_itemId].resalepoolitem = false;
    }

    function activepool(uint256 _poolid) public view returns (bool) {
        bool data = pools[_poolid].poolMetadata.active;
        return data;
    }

    function isResaleActive(uint256 _poolid)
        public
        view
        returns (uint256, bool)
    {
        uint256 _resaleId = pools[_poolid].poolMetadata.resaleId;
        uint256 price = resaleItem[_poolid][_resaleId].newPrice;
        bool active = resaleItem[_poolid][_resaleId].activeForSale;
        return (price, active);
    }

    function transferNFT(
        address _to,
        uint256 _tokenId,
        address nftContractAddress
    ) external {
        require(
            msg.sender == address(MarketPlaceAddress),
            "only nftMarketplace can Call this function"
        );
        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.transferFrom(address(this), _to, _tokenId);
    }

    function fetchVotedStatus(uint256 __poolId)
        public
        view
        returns (address[] memory, bool[] memory)
    {
        address[] memory members = participantList[__poolId];
        bool[] memory votedStatus = new bool[](members.length);

        for (uint256 i = 0; i < members.length; i++) {
            address participant = members[i];
            votedStatus[i] = participants[__poolId][participant].voted;
        }

        return (members, votedStatus);
    }

    function fetchPoolmember(uint256 __poolId)
        public
        view
        returns (address[] memory _participants)
    {
        _participants = participantList[__poolId];
    }

    // fetch All Pools of an Admin
    function fetchAllPoolsOfAdmin(address from)
        public
        view
        returns (PoolBasicData[] memory)
    {
        uint256 totalPools = _poolId.current();
        uint256 adminCount;
        for (uint256 i = 0; i < totalPools; i++) {
            if (pools[i + 1].admin == from) {
                adminCount++;
            }
        }

        PoolBasicData[] memory _userData = new PoolBasicData[](adminCount);
        for (uint256 i = 0; i < totalPools; i++) {
            if (pools[i + 1].admin == from) {
                PoolBasicData storage pool = pools[i + 1];
                _userData[i] = pool;
            }
        }
        return _userData;
    }

    // fetch All Pools of a Participant
    function fetchAllPoolsOfParticipant(address from)
        public
        view
        returns (PoolBasicData[] memory)
    {
        uint256 totalPools = _poolId.current();
        uint256 participantsCount;
        for (uint256 i = 0; i < totalPools; i++) {
            for (uint256 j = 0; j < participantList[i + 1].length; j++) {
                if (participantList[i + 1][j] == from) {
                    participantsCount++;
                }
            }
        }

        PoolBasicData[] memory _userData = new PoolBasicData[](
            participantsCount
        );
        for (uint256 i = 0; i < totalPools; i++) {
            for (uint256 j = 0; j < participantList[i + 1].length; j++) {
                if (participantList[i + 1][j] == from) {
                    _userData[i] = pools[i + 1];
                }
            }
        }
        return _userData;
    }

    // fetch All Pools available
    function fetchAllPools() public view returns (PoolBasicData[] memory) {
        uint256 totalPools = _poolId.current();
        PoolBasicData[] memory _userData = new PoolBasicData[](totalPools);
        for (uint256 i = 0; i < totalPools; i++) {
            PoolBasicData storage pool = pools[i + 1];
            _userData[i] = pool;
        }
        return _userData;
    }

    function fetchSinglePoolData(uint256 __poolId)
        public
        view
        returns (
            PoolBasicData memory _basicData,
            PoolMetadata memory _poolMetadata
        )
    {
        _basicData = pools[__poolId];
        _poolMetadata = pools[__poolId].poolMetadata;
    }

    function withDrawFunds(address _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
        IERC20(napaToken).transfer(_to, IERC20(napaToken).balanceOf(_to));
        IERC20(napaToken).transfer(_to, IERC20(usdtToken).balanceOf(_to));
    }

    // helper function for marketPlace
    function fetchPoolDetails(address from)
        public
        view
        returns (uint256[] memory itemIds)
    {
        uint256 totalPools = _poolId.current();
        uint256 Count = 0;
        uint256[] memory _itemIds = new uint256[](totalPools);

        for (uint256 i = 0; i < totalPools; i++) {
            if (pools[i + 1].admin == from) {
                PoolBasicData storage pool = pools[i + 1];
                _itemIds[i] = pool.itemId;
                Count += 1;
            }
        }
        return _itemIds;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}