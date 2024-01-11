// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";
import "./IERC20UpgradeableExtended.sol";
import "./IFayreMembershipCard721.sol";
import "./IFayreTokenLocker.sol";

contract FayreMarketplace is ERC2771ContextUpgradeable {
    /**
        E#1: ERC721 has no nft amount
        E#2: ERC1155 needs nft amount
        E#3: wrong base amount
        E#4: free offer expired
        E#5: token locker address not found 
        E#6: unable to send to treasury
        E#7: not the owner
        E#8: invalid trade type
        E#9: sale amount not specified
        E#10: sale expiration must be greater than start
        E#11: invalid network id
        E#12: cannot finalize your sale, cancel?
        E#13: cannot accept your offer
        E#14: salelist expired
        E#15: asset type not supported
        E#16: unable to send to sale owner
        E#17: token locker address already present
        E#18: unable to send to creator
        E#19: membership card address already present
        E#20: membership card address not found
        E#21: cannot finalize unexpired auction
        E#22: a sale already active
        E#23: a bid already active
    */

    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum TradeType {
        SALE_FIXEDPRICE,
        SALE_ENGLISHAUCTION,
        SALE_DUTCHAUCTION,
        BID
    }

    struct TradeRequest {
        uint256 networkId;
        address collectionAddress;
        uint256 tokenId;
        address owner;
        TradeType tradeType;
        AssetType assetType;
        uint256 nftAmount;
        address tokenAddress;
        uint256 amount;
        uint256 start;
        uint256 expiration;
        uint256 saleId;
        uint256 baseAmount;
    }

    struct TokenData {
        address creator;
        AssetType assetType;
        uint256 royaltiesPct;
        uint256[] salesIds;
        mapping(uint256 => uint256[]) bidsIds;
    }

    event PutOnSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, TradeRequest tradeRequest);
    event CancelSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, TradeRequest tradeRequest);
    event FinalizeSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, TradeRequest tradeRequest, address buyer);
    event PlaceBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, TradeRequest tradeRequest);
    event CancelBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, TradeRequest tradeRequest);
    event AcceptFreeOffer(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, TradeRequest tradeRequest, address nftOwner);
    event ERC20Transfer(address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
    event ERC721Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId);
    event ERC1155Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId, uint256 amount);

    uint256 public tradeFeePct;
    address public treasuryAddress;
    address[] public membershipCardsAddresses;
    address[] public tokenLockersAddresses;
    mapping(uint256 => TradeRequest) public sales;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public hasActiveSale;
    mapping(uint256 => TradeRequest) public bids;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public hasActiveBid;
    mapping(address => uint256) public tokenLockersRequiredAmounts;

    uint256 private _networkId;
    mapping(uint256 => mapping(address => mapping(uint256 => TokenData))) private _tokensData;
    uint256 private _currentSaleId;
    uint256 private _currentBidId;

    function setTradeFee(uint256 newTradeFeePct) external onlyOwner {
        tradeFeePct = newTradeFeePct;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function addMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                revert("E#19");

        membershipCardsAddresses.push(membershipCardsAddress);
    }

    function removeMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "E#20");

        membershipCardsAddresses[indexToDelete] = membershipCardsAddresses[membershipCardsAddresses.length - 1];

        membershipCardsAddresses.pop();
    }

    function addTokenLockerAddress(address tokenLockerAddress) external onlyOwner {
        for (uint256 i = 0; i < tokenLockersAddresses.length; i++)
            if (tokenLockersAddresses[i] == tokenLockerAddress)
                revert("E#17");

        tokenLockersAddresses.push(tokenLockerAddress);
    }

    function removeTokenLockerAddress(address tokenLockerAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockersAddresses.length; i++)
            if (tokenLockersAddresses[i] == tokenLockerAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "E#5");

        tokenLockersAddresses[indexToDelete] = tokenLockersAddresses[tokenLockersAddresses.length - 1];

        tokenLockersAddresses.pop();
    }

    function setTokenLockerRequiredAmount(address tokenLockerAddress, uint256 amount) external onlyOwner {
        tokenLockersRequiredAmounts[tokenLockerAddress] = amount;
    }

    function putOnSale(TradeRequest memory tradeRequest) external { 
        require(tradeRequest.owner == _msgSender(), "E#7");
        require(tradeRequest.networkId > 0, "E#11");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        _checkNftAmount(tradeRequest);

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.expiration > block.timestamp, "E#10");
        require(tradeRequest.tradeType == TradeType.SALE_FIXEDPRICE || tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION || tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION, "E#8");
        
        if (tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION)
            require(tradeRequest.baseAmount > 0 && tradeRequest.baseAmount < tradeRequest.amount, "E#3");

        require(!hasActiveSale[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()], "E#22");

        tradeRequest.collectionAddress = tradeRequest.collectionAddress;
        tradeRequest.start = block.timestamp;

        if (tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION)
            _clearSaleIdBids(tradeRequest.networkId, tradeRequest.collectionAddress, tradeRequest.tokenId, _currentSaleId);
            
        hasActiveSale[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()] = true;

        _tokensData[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId].salesIds.push(_currentSaleId);

        sales[_currentSaleId] = tradeRequest;

        emit PutOnSale(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentSaleId, tradeRequest);

        _currentSaleId++;
    }

    function cancelSale(uint256 saleId) external {
        require(sales[saleId].owner == _msgSender(), "E#7");

        sales[saleId].start = 0;
        sales[saleId].expiration = 0;

        _clearSaleData(saleId);

        emit CancelSale(sales[saleId].collectionAddress, sales[saleId].tokenId, saleId, sales[saleId]);
    }

    function finalizeSale(uint256 saleId) external {
        TradeRequest storage saleTradeRequest = sales[saleId];

        address buyer = address(0);

        if (saleTradeRequest.tradeType == TradeType.SALE_FIXEDPRICE) {
            require(saleTradeRequest.owner != _msgSender(), "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            saleTradeRequest.expiration = 0;

            buyer = _msgSender();

            _clearSaleData(saleId);

            _sendAmountToSeller(saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, saleTradeRequest.amount, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION) {
            require(saleTradeRequest.expiration <= block.timestamp, "E#21");

            uint256[] storage bidsIds = _tokensData[saleTradeRequest.networkId][saleTradeRequest.collectionAddress][saleTradeRequest.tokenId].bidsIds[saleId];

            uint256 highestBidId = 0;
            uint256 highestBidAmount = 0;

            for (uint256 i = 0; i < bidsIds.length; i++)
                if (bids[bidsIds[i]].amount >= saleTradeRequest.amount)
                    if (bids[bidsIds[i]].amount > highestBidAmount) {
                        highestBidId = bidsIds[i];
                        highestBidAmount = bids[bidsIds[i]].amount;
                    }
                    
            buyer = bids[highestBidId].owner;

            _clearSaleData(saleId);

            _sendAmountToSeller(saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, highestBidAmount, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION) {
            require(saleTradeRequest.owner != _msgSender(), "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            uint256 amountsDiff = saleTradeRequest.amount - saleTradeRequest.baseAmount;

            uint256 priceDelta = amountsDiff - ((amountsDiff * (block.timestamp - saleTradeRequest.start)) / (saleTradeRequest.expiration - saleTradeRequest.start));

            uint256 currentPrice = saleTradeRequest.baseAmount + priceDelta;
            
            saleTradeRequest.expiration = 0;

            buyer = _msgSender();

            _clearSaleData(saleId);

            _sendAmountToSeller(saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, currentPrice, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        }

        _transferAsset(saleTradeRequest.assetType, saleTradeRequest.collectionAddress, saleTradeRequest.owner, buyer, saleTradeRequest.tokenId, saleTradeRequest.nftAmount, "");

        emit FinalizeSale(saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, saleId, saleTradeRequest, buyer);
    }

    function placeBid(TradeRequest memory tradeRequest) external {
        require(tradeRequest.owner == _msgSender(), "E#7");
        require(tradeRequest.networkId > 0, "E#11");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        _checkNftAmount(tradeRequest);

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.tradeType == TradeType.BID, "E#8");
        require(!hasActiveBid[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()], "E#23");

        tradeRequest.start = block.timestamp;

        bids[_currentBidId] = tradeRequest;

        hasActiveBid[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][_msgSender()] = true;

        _tokensData[bids[_currentBidId].networkId][bids[_currentBidId].collectionAddress][bids[_currentBidId].tokenId].bidsIds[tradeRequest.saleId].push(_currentBidId);

        emit PlaceBid(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentBidId, tradeRequest);

        _currentBidId++;
    }

    function cancelBid(uint256 bidId) external {
        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner == _msgSender(), "E#7");

        bidTradeRequest.start = 0;
        bidTradeRequest.expiration = 0;

        hasActiveBid[bidTradeRequest.networkId][bidTradeRequest.collectionAddress][bidTradeRequest.tokenId][_msgSender()] = false;

        uint256[] storage bidsIds = _tokensData[bidTradeRequest.networkId][bidTradeRequest.collectionAddress][bidTradeRequest.tokenId].bidsIds[bidTradeRequest.saleId];

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < bidsIds.length; i++)
            if (bidsIds[i] == bidId)
                indexToDelete = i;

        bidsIds[indexToDelete] = bidsIds[bidsIds.length - 1];

        bidsIds.pop();

        emit CancelBid(bidTradeRequest.collectionAddress, bidTradeRequest.tokenId, bidId, bidTradeRequest);
    }

    function acceptFreeOffer(uint256 bidId) external {
        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner != _msgSender(), "E#13");
        require(bidTradeRequest.start > 0 && bidTradeRequest.expiration > block.timestamp, "E#4");

        bidTradeRequest.start = 0;
        bidTradeRequest.expiration = 0;

        hasActiveBid[bidTradeRequest.networkId][bidTradeRequest.collectionAddress][bidTradeRequest.tokenId][bidTradeRequest.owner] = false;

        _sendAmountToSeller(bidTradeRequest.networkId, bidTradeRequest.collectionAddress, bidTradeRequest.tokenId, bidTradeRequest.amount, bidTradeRequest.tokenAddress, _msgSender(), bidTradeRequest.owner);

        _transferAsset(bidTradeRequest.assetType, bidTradeRequest.collectionAddress, _msgSender(), bidTradeRequest.owner, bidTradeRequest.tokenId, bidTradeRequest.nftAmount, "");
    
        emit AcceptFreeOffer(bidTradeRequest.collectionAddress, bidTradeRequest.tokenId, bidId, bidTradeRequest, _msgSender());
    }

    function initialize() public initializer {
        __ERC2771ContextUpgradeable_init();

        _networkId = block.chainid;
    }

    function _clearSaleData(uint256 saleId) private {
        TradeRequest storage saleTradeRequest = sales[saleId];

        if (saleTradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION)
            _clearSaleIdBids(saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, 0);
            
        hasActiveSale[saleTradeRequest.networkId][saleTradeRequest.collectionAddress][saleTradeRequest.tokenId][saleTradeRequest.owner] = false;

        uint256[] storage salesIds = _tokensData[saleTradeRequest.networkId][saleTradeRequest.collectionAddress][saleTradeRequest.tokenId].salesIds;

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < salesIds.length; i++)
            if (salesIds[i] == saleId)
                indexToDelete = i;

        salesIds[indexToDelete] = salesIds[salesIds.length - 1];

        salesIds.pop();
    }

    function _sendAmountToSeller(uint256 networkId, address collectionAddress, uint256 tokenId, uint256 amount, address tokenAddress, address seller, address buyer) private {
        uint256 creatorRoyalties = 0;

        if (_tokensData[networkId][collectionAddress][tokenId].royaltiesPct > 0)
            creatorRoyalties = (amount * _tokensData[networkId][collectionAddress][tokenId].royaltiesPct) / 10 ** 20;

        uint256 saleFee = (amount * tradeFeePct) / 10 ** 20;

        uint256 ownerRemainingSaleFee = 0;

        ownerRemainingSaleFee = _processFee(seller, saleFee * 10 ** (18 - IERC20UpgradeableExtended(tokenAddress).decimals()), amount * 10 ** (18 - IERC20UpgradeableExtended(tokenAddress).decimals())) / 10 ** (18 - IERC20UpgradeableExtended(tokenAddress).decimals());

        _transferAsset(AssetType.ERC20, tokenAddress, buyer, seller, 0, amount - ownerRemainingSaleFee - creatorRoyalties, "E#16");

        if (ownerRemainingSaleFee > 0)
            _transferAsset(AssetType.ERC20, tokenAddress, buyer, treasuryAddress, 0, ownerRemainingSaleFee, "E#6");

        address creator = _tokensData[networkId][collectionAddress][tokenId].creator;

        if (creatorRoyalties > 0)
            _transferAsset(AssetType.ERC20, tokenAddress, buyer, creator, 0, creatorRoyalties, "E#18");
    }

    function _transferAsset(AssetType assetType, address contractAddress, address from, address to, uint256 tokenId, uint256 amount, string memory errorCode) private {
        if (assetType == AssetType.ERC20) {
            if (!IERC20UpgradeableExtended(contractAddress).transferFrom(from, to, amount))
                revert(errorCode);

            emit ERC20Transfer(contractAddress, from, to, amount);
        }
        else if (assetType == AssetType.ERC721) {
            IERC721Upgradeable(contractAddress).safeTransferFrom(from, to, tokenId);

            emit ERC721Transfer(contractAddress, from, to, tokenId);
        } 
        else if (assetType == AssetType.ERC1155) {
            IERC1155Upgradeable(contractAddress).safeTransferFrom(from, to, tokenId, amount, '');

            emit ERC1155Transfer(contractAddress, from, to, tokenId, amount);
        }      
    }

    function _processFee(address owner, uint256 fee, uint256 nftPrice) private returns(uint256) { 
        //Process locked tokens
        for (uint256 i = 0; i < tokenLockersAddresses.length; i++) {
            IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockersAddresses[i]).usersLockData(owner);

            if (lockData.amount > 0)
                if (lockData.amount >= tokenLockersRequiredAmounts[tokenLockersAddresses[i]] && lockData.expiration > block.timestamp)
                    fee = 0;
        }

        //Process membership cards
        if (fee > 0)
            for (uint256 i = 0; i < membershipCardsAddresses.length; i++) {
                uint256 membershipCardsAmount = IFayreMembershipCard721(membershipCardsAddresses[i]).balanceOf(owner);

                if (membershipCardsAmount <= 0)
                    continue;

                for (uint256 j = 0; j < membershipCardsAmount; j++) {
                    uint256 currentTokenId = IFayreMembershipCard721(membershipCardsAddresses[i]).tokenOfOwnerByIndex(owner, j);

                    (uint256 volume, uint256 nftPriceCap,) = IFayreMembershipCard721(membershipCardsAddresses[i]).membershipCardsData(currentTokenId);

                    bool canProcessVolume = true;

                    if (nftPriceCap > 0)
                        if (nftPrice > nftPriceCap)
                            canProcessVolume = false;

                    if (volume > 0 && canProcessVolume) {
                        uint256 amountToDeduct = fee;

                        if (volume < amountToDeduct)
                            amountToDeduct = volume;

                        IFayreMembershipCard721(membershipCardsAddresses[i]).decreaseMembershipCardVolume(currentTokenId, amountToDeduct);

                        fee -= amountToDeduct;

                        if (fee == 0)
                            break;
                    }
                }
            }

        return fee;
    }

    function _clearSaleIdBids(uint256 networkId, address collectionAddress, uint256 tokenId, uint256 saleId) private {
        uint256[] storage bidsIds = _tokensData[networkId][collectionAddress][tokenId].bidsIds[saleId];

        for (uint256 i = 0; i < bidsIds.length; i++) {
            bids[bidsIds[i]].start = 0;
            bids[bidsIds[i]].expiration = 0;

            hasActiveBid[networkId][collectionAddress][tokenId][bids[bidsIds[i]].owner] = false;
        }
        
        delete _tokensData[networkId][collectionAddress][tokenId].bidsIds[saleId];
    }

    function _checkNftAmount(TradeRequest memory tradeRequest) private pure {
        if (tradeRequest.assetType == AssetType.ERC721)
            require(tradeRequest.nftAmount == 0, "E#1");
        else if (tradeRequest.assetType == AssetType.ERC1155)
            require(tradeRequest.nftAmount > 0, "E#2");
    }
}
