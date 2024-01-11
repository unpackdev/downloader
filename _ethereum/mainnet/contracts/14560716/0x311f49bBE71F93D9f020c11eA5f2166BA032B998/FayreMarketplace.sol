// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AggregatorV3Interface.sol";
import "./IERC165Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20UpgradeableExtended.sol";
import "./IFayreSharedCollection721.sol";
import "./IFayreSharedCollection1155.sol";
import "./IFayreMembershipCard721.sol";
import "./IFayreTokenLocker.sol";


contract FayreMarketplace is OwnableUpgradeable {
    /**
        E#1: ERC721 has no nft amount
        E#2: ERC1155 needs nft amount
        E#3: must send liquidity
        E#4: insufficient funds for minting
        E#5: unable to refund extra liquidity
        E#6: unable to send liquidity to treasury
        E#7: not the owner
        E#8: invalid trade type
        E#9: sale amount not specified
        E#10: sale expiration must be greater than start
        E#11: invalid network id
        E#12: cannot finalize your sale, cancel?
        E#13: you must own the nft
        E#14: salelist expired
        E#15: asset type not supported
        E#16: unable to send liquidity to sale owner
        E#17: not enough liquidity
        E#18: unable to send liquidity to creator
        E#19: membership card address already present
        E#20: membership card address not found
        E#21: not enough free mints
        E#22: a sale already active
        E#23: a bid already active
        E#24: only marketplace manager
        E#25: cannot finalize unexpired auction
        E#26: you must specify token address
        E#27: error sending ERC20 tokens
        E#28: cannot accept your offer
        E#29: free offer expired
        E#30: liquidity not needed
        E#31: wrong base amount
        E#32: not collection owner
        E#33: empty collection name
        E#34: token locker address already present
        E#35: token locker address not found
        E#36: only a valid free minter can mint
    */

    enum AssetType {
        LIQUIDITY,
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

    struct MintTokenData {
        AssetType assetType;
        string tokenURI;
        uint256 amount;
        uint256 royaltiesPct;
        string collectionName;
    }

    struct FreeMinterData {
        address freeMinter;
        uint256 amount;
    }

    event Mint(address indexed owner, AssetType indexed assetType, uint256 indexed tokenId, uint256 amount, uint256 royaltiesPct, string tokenURI, string collectionName);
    event PutOnSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, TradeRequest tradeRequest);
    event CancelSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, TradeRequest tradeRequest);
    event FinalizeSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, TradeRequest tradeRequest, address buyer);
    event PlaceBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, TradeRequest tradeRequest);
    event CancelBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, TradeRequest tradeRequest);
    event AcceptFreeOffer(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, TradeRequest tradeRequest, address nftOwner);
    event LiquidityTransfer(address indexed to, uint256 amount);
    event ERC20Transfer(address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
    event ERC721Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId);
    event ERC1155Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId, uint256 amount);
    event SetFreeMinter(address indexed caller, uint256 indexed eventIndex, FreeMinterData freeMinterData);
    event RenameMintedCollection(string indexed collectionName, string indexed newCollectionName);
    event TransferMintedCollectionOwnership(string indexed collectionName, address from, address to);

    address public fayreSharedCollection721;
    address public fayreSharedCollection1155;
    address public oracleDataFeed;
    uint256 public mintFeeUSD;
    uint256 public tradeFeePct;
    address public treasuryAddress;
    address[] public membershipCardsAddresses;
    address[] public tokenLockersAddresses;  
    mapping(uint256 => TradeRequest) public sales;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public hasActiveSale;
    mapping(uint256 => TradeRequest) public bids;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public hasActiveBid;
    mapping(address => bool) public isMarketplaceManager;
    mapping(address => uint256) public remainingFreeMints;
    mapping(string => address) public mintedCollectionsOwners;
    mapping(address => uint256) public tokenLockersRequiredAmounts;
    bool public onlyFreeMintersCanMint;


    uint256 private _networkId;
    mapping(uint256 => mapping(address => mapping(uint256 => TokenData))) private _tokensData;
    uint256 private _currentSaleId;
    uint256 private _currentBidId;
    uint256 private _currentEventsIndex;

    modifier onlyMarketplaceManager() {
        require(isMarketplaceManager[msg.sender], "E#24");
        _;
    }

    function setFayreSharedCollection721(address newFayreSharedCollection721) external onlyOwner {
        fayreSharedCollection721 = newFayreSharedCollection721;
    }

    function setFayreSharedCollection1155(address newFayreSharedCollection1155) external onlyOwner {
        fayreSharedCollection1155 = newFayreSharedCollection1155;
    }

    function setOracleDataFeedAddress(address newOracleDataFeed) external onlyOwner {
        oracleDataFeed = newOracleDataFeed;
    }

    function setMintFee(uint256 newMintFeeUSD) external onlyOwner {
        mintFeeUSD = newMintFeeUSD;
    }

    function setTradeFee(uint256 newTradeFeePct) external onlyOwner {
        tradeFeePct = newTradeFeePct;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function setOnlyFreeMintersCanMint(bool newOnlyFreeMintersCanMint) external onlyOwner {
        onlyFreeMintersCanMint = newOnlyFreeMintersCanMint;
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
                revert("E#34");

        tokenLockersAddresses.push(tokenLockerAddress);
    }

    function removeTokenLockerAddress(address tokenLockerAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockersAddresses.length; i++)
            if (tokenLockersAddresses[i] == tokenLockerAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "E#35");

        tokenLockersAddresses[indexToDelete] = tokenLockersAddresses[tokenLockersAddresses.length - 1];

        tokenLockersAddresses.pop();
    }

    function setTokenLockerRequiredAmount(address tokenLockerAddress, uint256 amount) external onlyOwner {
        tokenLockersRequiredAmounts[tokenLockerAddress] = amount;
    }

    function setAddressAsMarketplaceManager(address marketplaceManagerAddress) external onlyOwner {
        isMarketplaceManager[marketplaceManagerAddress] = true;
    }

    function unsetAddressAsMarketplaceManager(address marketplaceManagerAddress) external onlyOwner {
        isMarketplaceManager[marketplaceManagerAddress] = false;
    }

    function setFreeMinters(FreeMinterData[] calldata freeMintersData) external onlyMarketplaceManager {
        for (uint256 i = 0; i < freeMintersData.length; i++) {
            remainingFreeMints[freeMintersData[i].freeMinter] = freeMintersData[i].amount;

            emit SetFreeMinter(msg.sender, _currentEventsIndex, freeMintersData[i]);

            _currentEventsIndex++;
        } 
    }

    function batchMint(MintTokenData[] calldata mintTokensData) external {
        require(remainingFreeMints[msg.sender] >= mintTokensData.length, "E#21");

        for (uint256 i = 0; i < mintTokensData.length; i++) {
            remainingFreeMints[msg.sender]--;

            _mint(mintTokensData[i]); 
        }
    }

    function mint(AssetType assetType, string memory tokenURI, uint256 amount, uint256 royaltiesPct, string memory collectionName) external payable returns(uint256) {
        if (bytes(collectionName).length > 0)
            if (mintedCollectionsOwners[collectionName] != address(0))
                require(mintedCollectionsOwners[collectionName] == msg.sender, "E#32");
            else
                mintedCollectionsOwners[collectionName] = msg.sender;
        
        if (onlyFreeMintersCanMint)
            require(remainingFreeMints[msg.sender] > 0, "E#36");

        if (remainingFreeMints[msg.sender] > 0) {
            require(msg.value == 0, "E#30");

            remainingFreeMints[msg.sender]--;  
        } else {
            uint256 remaningMintFeeUSD = _processFee(msg.sender, mintFeeUSD, 0);

            uint256 remaningMintFee = 0;

            if (remaningMintFeeUSD > 0) {
                require(msg.value > 0, "E#3");

                remaningMintFee = _convertUSDToLiquidity(remaningMintFeeUSD);

                require(msg.value >= remaningMintFee, "E#4");

                _transferAsset(AssetType.LIQUIDITY, address(0), address(0), treasuryAddress, 0, remaningMintFee, "E#6");
            }

            uint256 valueToRefund = msg.value - remaningMintFee;

            if (valueToRefund > 0)
                _transferAsset(AssetType.LIQUIDITY, address(0), address(0), msg.sender, 0, valueToRefund, "E#5");
        }

        MintTokenData memory mintTokenData = MintTokenData(assetType, tokenURI, amount, royaltiesPct, collectionName);

        uint256 tokenId = _mint(mintTokenData);

        return tokenId;
    }

    function putOnSale(TradeRequest memory tradeRequest) external { 
        require(tradeRequest.owner == msg.sender, "E#7");
        require(tradeRequest.networkId > 0, "E#11");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        if (tradeRequest.assetType == AssetType.ERC721) {
            require(IERC721Upgradeable(tradeRequest.collectionAddress).ownerOf(tradeRequest.tokenId) == msg.sender, "E#13");
            require(tradeRequest.nftAmount == 0, "E#1");
        } 
        else if (tradeRequest.assetType == AssetType.ERC1155) {
            require(IERC1155Upgradeable(tradeRequest.collectionAddress).balanceOf(msg.sender, tradeRequest.tokenId) > 0, "E#13");
            require(tradeRequest.nftAmount > 0, "E#2");
        }

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.expiration > block.timestamp, "E#10");
        require(tradeRequest.tradeType == TradeType.SALE_FIXEDPRICE || tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION || tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION, "E#8");
        
        if (tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION)
            require(tradeRequest.baseAmount > 0 && tradeRequest.baseAmount < tradeRequest.amount, "E#31");

        require(!hasActiveSale[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][msg.sender], "E#22");

        tradeRequest.collectionAddress = tradeRequest.collectionAddress;
        tradeRequest.start = block.timestamp;

        if (tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION)
            _clearSaleIdBids(tradeRequest.networkId, tradeRequest.collectionAddress, tradeRequest.tokenId, _currentSaleId);
            
        hasActiveSale[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][msg.sender] = true;

        _tokensData[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId].salesIds.push(_currentSaleId);

        sales[_currentSaleId] = tradeRequest;

        emit PutOnSale(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentSaleId, tradeRequest);

        _currentSaleId++;
    }

    function cancelSale(uint256 saleId) external {
        require(sales[saleId].owner == msg.sender, "E#7");

        sales[saleId].start = 0;
        sales[saleId].expiration = 0;

        _clearSaleData(saleId);

        emit CancelSale(sales[saleId].collectionAddress, sales[saleId].tokenId, saleId, sales[saleId]);
    }

    function finalizeSale(uint256 saleId) external payable {
        TradeRequest storage saleTradeRequest = sales[saleId];

        address buyer = address(0);

        if (saleTradeRequest.tradeType == TradeType.SALE_FIXEDPRICE) {
            require(msg.value >= saleTradeRequest.amount, "E#17");
            require(saleTradeRequest.owner != msg.sender, "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            saleTradeRequest.expiration = 0;

            buyer = msg.sender;

            _clearSaleData(saleId);

            _sendAmountToSeller(AssetType.LIQUIDITY, saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, saleTradeRequest.amount, address(0), saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION) {
            require(saleTradeRequest.expiration <= block.timestamp, "E#25");

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

            _sendAmountToSeller(AssetType.ERC20, saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, highestBidAmount, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION) {
            require(saleTradeRequest.owner != msg.sender, "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            uint256 amountsDiff = saleTradeRequest.amount - saleTradeRequest.baseAmount;

            uint256 priceDelta = amountsDiff - ((amountsDiff * (block.timestamp - saleTradeRequest.start)) / (saleTradeRequest.expiration - saleTradeRequest.start));

            uint256 currentPrice = saleTradeRequest.baseAmount + priceDelta;
            
            require(msg.value >= currentPrice, "E#17");

            saleTradeRequest.expiration = 0;

            buyer = msg.sender;

            _clearSaleData(saleId);

            _sendAmountToSeller(AssetType.LIQUIDITY, saleTradeRequest.networkId, saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, currentPrice, address(0), saleTradeRequest.owner, buyer);
        }

        if (buyer != address(0))
            _transferAsset(saleTradeRequest.assetType, saleTradeRequest.collectionAddress, saleTradeRequest.owner, buyer, saleTradeRequest.tokenId, saleTradeRequest.nftAmount, "");

        emit FinalizeSale(saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, saleId, saleTradeRequest, buyer);
    }

    function placeBid(TradeRequest memory tradeRequest) external {
        require(tradeRequest.owner == msg.sender, "E#7");
        require(tradeRequest.networkId > 0, "E#11");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        if (tradeRequest.assetType == AssetType.ERC721) {
            require(tradeRequest.nftAmount == 0, "E#1");
        } 
        else if (tradeRequest.assetType == AssetType.ERC1155) {
            require(tradeRequest.nftAmount > 0, "E#2");
        }

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.tradeType == TradeType.BID, "E#8");
        require(!hasActiveBid[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][msg.sender], "E#23");

        tradeRequest.start = block.timestamp;

        bids[_currentBidId] = tradeRequest;

        hasActiveBid[tradeRequest.networkId][tradeRequest.collectionAddress][tradeRequest.tokenId][msg.sender] = true;

        _tokensData[bids[_currentBidId].networkId][bids[_currentBidId].collectionAddress][bids[_currentBidId].tokenId].bidsIds[tradeRequest.saleId].push(_currentBidId);

        emit PlaceBid(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentBidId, tradeRequest);

        _currentBidId++;
    }

    function cancelBid(uint256 bidId) external {
        require(bids[bidId].owner == msg.sender, "E#7");

        bids[bidId].start = 0;
        bids[bidId].expiration = 0;

        hasActiveBid[bids[bidId].networkId][bids[bidId].collectionAddress][bids[bidId].tokenId][msg.sender] = false;

        uint256[] storage bidsIds = _tokensData[bids[bidId].networkId][bids[bidId].collectionAddress][bids[bidId].tokenId].bidsIds[bids[bidId].saleId];

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < bidsIds.length; i++)
            if (bidsIds[i] == bidId)
                indexToDelete = i;

        bidsIds[indexToDelete] = bidsIds[bidsIds.length - 1];

        bidsIds.pop();

        emit CancelBid(bids[bidId].collectionAddress, bids[bidId].tokenId, bidId, bids[bidId]);
    }

    function acceptFreeOffer(uint256 bidId) external {
        require(bids[bidId].owner != msg.sender, "E#28");
        require(bids[bidId].start > 0 && bids[bidId].expiration > block.timestamp, "E#29");

        bids[bidId].start = 0;
        bids[bidId].expiration = 0;

        hasActiveBid[bids[bidId].networkId][bids[bidId].collectionAddress][bids[bidId].tokenId][bids[bidId].owner] = false;

        _sendAmountToSeller(AssetType.ERC20, bids[bidId].networkId, bids[bidId].collectionAddress, bids[bidId].tokenId, bids[bidId].amount, bids[bidId].tokenAddress, msg.sender, bids[bidId].owner);

        _transferAsset(bids[bidId].assetType, bids[bidId].collectionAddress, msg.sender, bids[bidId].owner, bids[bidId].tokenId, bids[bidId].nftAmount, "");
    
        emit AcceptFreeOffer(bids[bidId].collectionAddress, bids[bidId].tokenId, bidId, bids[bidId], msg.sender);
    }

    function transferMintedCollectionOwnership(string calldata collectionName, address to) external {
        require(mintedCollectionsOwners[collectionName] == msg.sender, "E#32");

        mintedCollectionsOwners[collectionName] = to;

        emit TransferMintedCollectionOwnership(collectionName, msg.sender, to);
    }

    function renameMintedCollection(string calldata collectionName, string calldata newCollectionName) external onlyMarketplaceManager {
        require(bytes(newCollectionName).length > 0, "E#33");

        mintedCollectionsOwners[newCollectionName] = mintedCollectionsOwners[collectionName];
        
        mintedCollectionsOwners[collectionName] = address(0);

        emit RenameMintedCollection(collectionName, newCollectionName);
    }

    function initialize(uint256 networkId) public initializer {
        __Ownable_init();

        _networkId = networkId;
    }

    function _mint(MintTokenData memory mintTokenData) private returns(uint256) {
        require(mintTokenData.assetType == AssetType.ERC721 || mintTokenData.assetType == AssetType.ERC1155, "E#15");

        uint256 tokenId = 0;

        if (mintTokenData.assetType == AssetType.ERC721) {
            require(mintTokenData.amount == 0, "E#1");

            tokenId = IFayreSharedCollection721(fayreSharedCollection721).mint(msg.sender, mintTokenData.tokenURI);

            _tokensData[_networkId][fayreSharedCollection721][tokenId].creator = msg.sender;
            _tokensData[_networkId][fayreSharedCollection721][tokenId].royaltiesPct = mintTokenData.royaltiesPct;
        } else {
            require(mintTokenData.amount > 0, "E#2");

            tokenId = IFayreSharedCollection1155(fayreSharedCollection1155).mint(msg.sender, mintTokenData.tokenURI, mintTokenData.amount);

            _tokensData[_networkId][fayreSharedCollection1155][tokenId].creator = msg.sender;
            _tokensData[_networkId][fayreSharedCollection1155][tokenId].royaltiesPct = mintTokenData.royaltiesPct;
        }

        emit Mint(msg.sender, mintTokenData.assetType, tokenId, mintTokenData.amount, mintTokenData.royaltiesPct, mintTokenData.tokenURI, mintTokenData.collectionName);

        return tokenId;
    }

    function _clearSaleData(uint256 saleId) private {
        if (sales[saleId].tradeType == TradeType.SALE_ENGLISHAUCTION)
            _clearSaleIdBids(sales[saleId].networkId, sales[saleId].collectionAddress, sales[saleId].tokenId, 0);
            
        hasActiveSale[sales[saleId].networkId][sales[saleId].collectionAddress][sales[saleId].tokenId][sales[saleId].owner] = false;

        uint256[] storage salesIds = _tokensData[sales[saleId].networkId][sales[saleId].collectionAddress][sales[saleId].tokenId].salesIds;

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < salesIds.length; i++)
            if (salesIds[i] == saleId)
                indexToDelete = i;

        salesIds[indexToDelete] = salesIds[salesIds.length - 1];

        salesIds.pop();
    }

    function _sendAmountToSeller(AssetType assetType, uint256 networkId, address collectionAddress, uint256 tokenId, uint256 amount, address tokenAddress, address seller, address buyer) private {
        uint256 creatorRoyalties = 0;

        if (_tokensData[networkId][collectionAddress][tokenId].royaltiesPct > 0)
            creatorRoyalties = (amount * _tokensData[networkId][collectionAddress][tokenId].royaltiesPct) / 10 ** 20;

        uint256 saleFee = (amount * tradeFeePct) / 10 ** 20;

        uint256 ownerRemainingSaleFee = 0;

        address from;
        
        if (assetType == AssetType.LIQUIDITY) {
            from = address(0);

            ownerRemainingSaleFee = _convertUSDToLiquidity(_processFee(seller, _convertLiquidityToUSD(saleFee), _convertLiquidityToUSD(amount)));
        }
        else {
            from = buyer;

            ownerRemainingSaleFee = _processFee(seller, saleFee * 10 ** (18 - IERC20UpgradeableExtended(tokenAddress).decimals()), amount * 10 ** (18 - IERC20UpgradeableExtended(tokenAddress).decimals())) / 10 ** (18 - IERC20UpgradeableExtended(tokenAddress).decimals());
        }

        _transferAsset(assetType, tokenAddress, from, seller, 0, amount - ownerRemainingSaleFee - creatorRoyalties, "E#16");

        if (ownerRemainingSaleFee > 0)
            _transferAsset(assetType, tokenAddress, from, treasuryAddress, 0, ownerRemainingSaleFee, "E#6");

        address creator = _tokensData[networkId][collectionAddress][tokenId].creator;

        if (creatorRoyalties > 0)
            _transferAsset(assetType, tokenAddress, from, creator, 0, creatorRoyalties, "E#18");

        if (assetType == AssetType.LIQUIDITY)
            if (msg.value > amount)
                _transferAsset(AssetType.LIQUIDITY, address(0), address(0), msg.sender, 0, msg.value - amount, "E#5");
    }

    function _transferAsset(AssetType assetType, address contractAddress, address from, address to, uint256 tokenId, uint256 amount, string memory errorCode) private {
        if (assetType == AssetType.LIQUIDITY) {
            (bool liquiditySendSuccess, ) = to.call{value: amount }("");

            require(liquiditySendSuccess, errorCode);

            emit LiquidityTransfer(to, amount);
        }
        else if (assetType == AssetType.ERC20) {
            if (!IERC20UpgradeableExtended(contractAddress).transferFrom(from, to, amount))
                revert("E#27");

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

                    if (nftPriceCap > 0)
                        if (nftPriceCap < nftPrice)
                            continue;

                    if (volume > 0) {
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

    function _convertUSDToLiquidity(uint256 usdAmount) private view returns(uint256) {
        (, int256 ethUSDPrice, , , ) = AggregatorV3Interface(oracleDataFeed).latestRoundData();

        uint8 oracleDataDecimals = AggregatorV3Interface(oracleDataFeed).decimals();

        return (usdAmount * (10 ** oracleDataDecimals)) / uint256(ethUSDPrice);
    }

    function _convertLiquidityToUSD(uint256 liquidityAmount) private view returns(uint256) {
        (, int256 ethUSDPrice, , , ) = AggregatorV3Interface(oracleDataFeed).latestRoundData();

        uint8 oracleDataDecimals = AggregatorV3Interface(oracleDataFeed).decimals();

        return (liquidityAmount * uint256(ethUSDPrice)) / (10 ** oracleDataDecimals);
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
}
