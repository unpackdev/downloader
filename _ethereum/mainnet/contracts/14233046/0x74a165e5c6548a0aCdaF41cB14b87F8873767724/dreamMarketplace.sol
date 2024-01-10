// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IDreamNFT {
    function minter(uint256 id) external returns (address);
}

// Not to be confused with the actual WETH contract. This is a simple
// contract to keep track of ETH/BNB the user is owned by the contract.
// The user can withdraw it at any moment, it's not a token, hence it's not
// transferable. The marketplace will automatically try to refund the ETH to
// the user (e.g outbid, NFT sold) with a gas limit. This is simply backup
// when the ETH/BNB could not be sent to the user/address. For example, if
// the user is a smart contract that uses a lot of gas on it's payable.
contract WrappedETH is ReentrancyGuard {
    mapping(address => uint256) public wethBalance;
    function claimETH() external {
        uint256 refund = wethBalance[msg.sender];
        wethBalance[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: refund}("");
        // If the tx failed, restore back their balance.
        if(!success) {
            wethBalance[msg.sender] = refund;
        }
    }

    // claimETHForUser tries to payout the user's owned balance with
    // a gas limit. Does not throw if it failed to send.
    function claimETHForUser(address user) public {
        uint256 refund = wethBalance[user];
        wethBalance[user] = 0;
        (bool success,) = user.call{value: refund, gas: 3500}("");
        // If the tx failed, restore back their balance.
        if(!success) {
            wethBalance[user] = refund;
        }
    }

    // rewardETHToUser tries to send specified amount of ETH to the user.
    // If it cannot, it will add it to their balance. It will NOT throw.
    // Used for paying out other users safely, e.g when outbidding someone.
    function rewardETHToUser(address user, uint256 amount) internal {
        (bool success,) = user.call{value: amount, gas: 3500}("");
        if(!success) {
            wethBalance[user] += amount;
        }
    }
}

contract Buyback {
    // Uniswap V2 Router address for buyback functionality.
    IUniswapV2Router02 public uniswapV2Router;
    // Keep store of the WETH address to save on gas.
    address WETH;

    // devWalletAddress is the Dream development address for 10% fees, and buyback.
    address internal devWalletAddress;
    address public dreamTokenAddress;

    uint256 ethToBuybackWith = 0;

    event UniswapRouterUpdated(
        address newAddress
    );

    event DreamBuyback(
        uint256 ethSpent
    );

    function updateBuybackUniswapRouter(address newRouterAddress) internal {
        uniswapV2Router = IUniswapV2Router02(newRouterAddress);
        WETH = uniswapV2Router.WETH();
        emit UniswapRouterUpdated(newRouterAddress);
    }

    function buybackDream() external {
        require(msg.sender == address(this), "can only be called by the contract");
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = dreamTokenAddress;
        uint256 amount = ethToBuybackWith;
        ethToBuybackWith = 0;
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            devWalletAddress,
            block.timestamp
        );
        emit DreamBuyback(amount);
    }

    function swapETHForTokens(uint256 amount) internal {
        ethToBuybackWith += amount;
        // 500k gas is more than enough.
        try this.buybackDream{gas: 500000}() {} catch {}
    }
}

contract DreamMarketplace is ReentrancyGuard, Ownable, WrappedETH, Buyback {
    // MarketItem consists of buy-now and bid items.
    // Auction refers to items that can be bid on.
    // An item can either be buy-now or bid, or both.
    struct MarketItem {
        uint256 tokenId;

        address payable seller;

        // If purchasePrice is non-0, item can be bought out-right for that price
        // if bidPrice is non-0, item can be bid upon.
        uint256 purchasePrice;
        uint256 bidPrice;

        uint8 state;
        uint64 listingCreationTime;
        uint64 auctionStartTime; // Set when first bid is received. 0 until then.
        uint64 auctionEndTime; // Initially it is the DURATION of the auction.
                               // After the first bid, it is set to the END time
                               // of the auction.
        // Defaults to 0. When 0, no bid has been placed yet.
        address payable highestBidder;
    }

    struct BidHistory {       
        address bidder;
        uint256 bidAmount;
        uint64 bidTime;
    }

    uint8 constant ON_MARKET = 0;
    uint8 constant SOLD = 1;
    uint8 constant CANCELLED = 2;

    uint256 buybackResaleFeePercentage = 5;
    uint256 buybackMinterFeePercentage = 10;
    uint256 artistFeePercentage = 5;
    uint256 devFeePercentage = 10;
    uint256 nextBidPricePercentage = 105;


    uint256 delistCooldown = 600;
    uint256 extendedTime = 300;

    // itemsOnMarket is a list of all items, historic and current, on the marketplace.
    // This includes items all of states, i.e items are never removed from this list.
    MarketItem[] public itemsOnMarket;
    
    mapping(uint256 => BidHistory[]) public itemsOnMarketBidHistories;

    // dreamNFTAddress is the address for the Dream NFT address.
    address public dreamNFTAddress;

    event AuctionItemAdded(
        uint256 marketId,
        uint256 tokenId,
        address tokenAddress,
        uint256 bidPrice,
        uint256 auctionDuration
    );

    event FixedPriceItemAdded(
        uint256 marketId,
        uint256 tokenId,
        address tokenAddress,
        uint256 purchasePrice
    );

    event ItemSold(
        uint256 marketId,
        uint256 tokenId,
        address buyer,
        uint256 purchasePrice,
        uint256 bidPrice
    );

    event HighestBidIncrease(
        uint256 marketId,
        address bidder,
        uint256 amount,
        uint256 auctionEndTime
    );

    event PriceReduction(
        uint256 marketId,
        uint256 newPurchasePrice,
        uint256 newBidPrice
    );

    event ItemPulledFromMarket(uint256 id);

    constructor(address _dreamNFTAddress, address _uniswapRouterAddress, address _dreamTokenAddress, address _devWallet) {
        dreamNFTAddress = _dreamNFTAddress;        
        updateBuybackUniswapRouter(_uniswapRouterAddress);
        dreamTokenAddress = _dreamTokenAddress;
        devWalletAddress = _devWallet;
    }

    function updateUniswapRouter(address newRouterAddress) external onlyOwner {
        updateBuybackUniswapRouter(newRouterAddress);
    }

    function updateDreamNFTAddress(address newAddress) external onlyOwner {
        dreamNFTAddress = newAddress;
    }

    function updateDreamTokenAddress(address newAddress) external onlyOwner {
        dreamTokenAddress = newAddress;
    }

    function isMinter(uint256 id, address target) internal returns (bool) {
        IDreamNFT sNFT = IDreamNFT(dreamNFTAddress);
        return sNFT.minter(id) == target;
    }

    function minter(uint256 id) internal returns (address) {
        IDreamNFT sNFT = IDreamNFT(dreamNFTAddress);
        return sNFT.minter(id);
    }

    function setFees(uint256 _buybackResaleFeePercentage, 
        uint256 _buybackMinterFeePercentage,
        uint256 _artistFeePercentage,
        uint256 _devFeePercentage,
        uint256 _nextBidPricePercentage ) external onlyOwner {
        buybackResaleFeePercentage = _buybackResaleFeePercentage;
        buybackMinterFeePercentage = _buybackMinterFeePercentage;
        artistFeePercentage = _artistFeePercentage;
        devFeePercentage = _devFeePercentage;
        nextBidPricePercentage = _nextBidPricePercentage;
    }

    function changeDevWalletAddress(address newAddress) external onlyOwner{
        devWalletAddress = newAddress;
    }

    function setDelistCooldown(uint256 cooldown) external onlyOwner {
        delistCooldown = cooldown;
    }

    function setExtendedTime(uint256 time) external onlyOwner {
        extendedTime = time;
    }

    function handleFees(uint256 tokenId, uint256 amount, bool isMinterSale) internal returns (uint256) {
        uint256 buybackFee;
        if(!isMinterSale) {
            // In resale, 5% buyback and 5% to artist.
            // 90% to seller.
            buybackFee = amount * buybackResaleFeePercentage / 100;
            uint256 artistFee = amount * artistFeePercentage / 100;
            rewardETHToUser(minter(tokenId), artistFee);
            amount = amount - artistFee;
        } else {
            // When it's the minter selling, they get 80%
            // 10% to buyback
            // 10% to Dream dev wallet.
            buybackFee = amount * buybackMinterFeePercentage / 100;
            uint256 devFee = amount * devFeePercentage / 100;
            rewardETHToUser(devWalletAddress, devFee);
            amount = amount - devFee;
        }
        swapETHForTokens(buybackFee);
        return amount - buybackFee;
    }
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

   function withdrawStuckNFT(address nftAddress, uint256 tokenId) public onlyOwner{
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function createAuctionItem(
        uint256 tokenId,
        address seller,
        uint256 purchasePrice,
        uint256 startingBidPrice,
        uint256 biddingTime
    ) internal {
        itemsOnMarket.push(
            MarketItem(
                tokenId,
                payable(seller),
                purchasePrice,
                startingBidPrice,
                ON_MARKET,
                uint64(block.timestamp),
                uint64(0),
                uint64(biddingTime),
                payable(address(0))
            )
        );
    }
    
    // purchasePrice is the direct purchasing price. Starting bid price
    // is the starting price for bids. If purchase price is 0, item cannot
    // be bought directly. Similarly for startingBidPrice, if it's 0, item
    // cannot be bid upon. One of them must be non-zero.
    function listItemOnAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 purchasePrice,
        uint256 startingBidPrice,
        uint256 biddingTime
    )
        external
        returns (uint256)
    {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "Missing Item Ownership");
        require(tokenContract.getApproved(tokenId) == address(this), "Missing transfer approval");

        require(purchasePrice > 0 || startingBidPrice > 0, "Item must have a price");
        require(startingBidPrice == 0 || biddingTime > 60, "Bidding time must be above one minute");

        uint256 newItemId = itemsOnMarket.length;
        createAuctionItem(
            tokenId,
            msg.sender,
            purchasePrice,
            startingBidPrice,
            biddingTime
        );
 
        IERC721(dreamNFTAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        if(purchasePrice > 0) {            
            emit FixedPriceItemAdded(newItemId, tokenId, tokenAddress, purchasePrice);
        }

        if(startingBidPrice > 0) {
            emit AuctionItemAdded(
                newItemId,
                tokenId,
                dreamNFTAddress,
                startingBidPrice,
                biddingTime
            );
        }
        return newItemId;
    }

    function buyFixedPriceItem(uint256 id)
        external
        payable
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];
        require(item.state == ON_MARKET, "Item not for sale");
        require(msg.value >= item.purchasePrice, "Not enough funds sent");
        require(item.purchasePrice > 0, "Item does not have a purchase price.");
        require(msg.sender != item.seller, "Seller can't buy");
        item.state = SOLD;
        IERC721(dreamNFTAddress).safeTransferFrom(
            address(this),
            msg.sender,
            item.tokenId
        ); 
        uint256 netPrice = handleFees(item.tokenId, item.purchasePrice, isMinter(item.tokenId, item.seller));
        rewardETHToUser(item.seller, netPrice);
        emit ItemSold(id, item.tokenId, msg.sender, item.purchasePrice, item.bidPrice);
        itemsOnMarket[id] = item;

        // If the user sent excess ETH/BNB, send any extra back to the user.
        uint256 refundableEther = msg.value - item.purchasePrice;
        if(refundableEther > 0) {
            rewardETHToUser(msg.sender, refundableEther);
        }
    }

    function placeBid(uint256 id)
        external
        payable
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];

        require(item.state == ON_MARKET, "Item not for sale");
        
        require(block.timestamp < item.auctionEndTime || item.highestBidder == address(0), "Auction has ended");
        
        if (item.highestBidder != address(0)) {
            require(msg.value >= item.bidPrice * nextBidPricePercentage / 100, "Bid must be 5% higher than previous bid");
        } else {
            require(msg.value >= item.bidPrice, "Too low bid");

            // First bid!
            item.auctionStartTime = uint64(block.timestamp);
            // item.auctionEnd is the auction duration. Add current time to it
            // to set it to the end time.
            item.auctionEndTime += uint64(block.timestamp);
        }

        address previousBidder = item.highestBidder;
        // Return ETH to previous highest bidder.
        if (previousBidder != address(0)) {
            rewardETHToUser(previousBidder, item.bidPrice);
        }

        item.highestBidder = payable(msg.sender);
        item.bidPrice = msg.value;
        // Extend the auction time by 5 minutes if there is less than 5 minutes remaining.
        // This is to prevent snipers sniping in the last block, and give everyone a chance
        // to bid.
        if ((item.auctionEndTime - block.timestamp) < extendedTime){
            item.auctionEndTime = uint64(block.timestamp + extendedTime);
        }

        emit HighestBidIncrease(id, msg.sender, msg.value, item.auctionEndTime);

        itemsOnMarket[id] = item;

        itemsOnMarketBidHistories[id].push(                
                BidHistory(
                    msg.sender,
                    msg.value,
                    uint64(block.timestamp)                   
                )
            );
    }

    function closeAuction(uint256 id)
        external
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];

        require(item.state == ON_MARKET, "Item not for sale");
        require(item.bidPrice > 0, "Item is not on auction.");
        require(item.highestBidder != address(0), "No bids placed");
        require(block.timestamp > item.auctionEndTime, "Auction is still on going");
        
        item.state = SOLD;
        
        IERC721(dreamNFTAddress).transferFrom(
            address(this),
            item.highestBidder,
            item.tokenId
        );
        
        uint256 netPrice = handleFees(item.tokenId, item.bidPrice, isMinter(item.tokenId, item.seller));
        rewardETHToUser(item.seller, netPrice);
        
        emit ItemSold(id, item.tokenId, item.highestBidder, item.purchasePrice, item.bidPrice);
        itemsOnMarket[id] = item;
    }

    function reducePrice(
        uint256 id,
        uint256 reducedPrice,
        uint256 reducedBidPrice
    )
        external
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];
        require(item.state == ON_MARKET, "Item not for sale");
        require(msg.sender == item.seller, "Only the item seller can trigger a price reduction");
        require(block.timestamp >= item.listingCreationTime + delistCooldown, "Must wait after listing before lowering the listing price");
        require(item.highestBidder == address(0), "Cannot reduce price once a bid has been placed");
        require(reducedBidPrice > 0 || reducedPrice > 0, "Must reduce price");

        if (reducedPrice > 0) {
            require(
                item.purchasePrice > 0 && reducedPrice <= item.purchasePrice * 95 / 100,
                "Reduced price must be at least 5% less than the current price"
            );
            item.purchasePrice = reducedPrice;
        }

        if (reducedBidPrice > 0) {
            require(
                item.bidPrice > 0 && reducedBidPrice <= item.bidPrice * 95 / 100,
                "Reduced price must be at least 5% less than the current price"
            );
            item.bidPrice = reducedPrice;
        }

        itemsOnMarket[id] = item;
        emit PriceReduction(
            id,
            item.purchasePrice,
            item.bidPrice
        );
    }

    function pullFromMarket(uint256 id)
        external
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];

        require(item.state == ON_MARKET, "Item not for sale");
        require(msg.sender == item.seller, "Only the item seller can pull an item from the marketplace");

        // Up for debate: Currently we don't allow items to be pulled if it's been bid on
        require(item.highestBidder == address(0), "Cannot pull from market once a bid has been placed");
        require(block.timestamp >= item.listingCreationTime + 600, "Must wait ten minutes after listing before pulling from the market");
        item.state = CANCELLED;

        IERC721(dreamNFTAddress).transferFrom(
            address(this),
            item.seller,
            item.tokenId
        );
        itemsOnMarket[id] = item;

        emit ItemPulledFromMarket(id);
    }

    // A method for retrieve a NftMarketplaceId, given a NFTID
    function getMarketplaceId(uint256 tokenId)
        external
        view returns (uint256 marketplaceID)
    {
        bool result = false;
        for(uint256 idx = 0; idx < itemsOnMarket.length; idx++) {
            MarketItem memory item = itemsOnMarket[idx];
            if (item.tokenId == tokenId) {
                result = true;
                marketplaceID = idx;
                return marketplaceID;
            }            
        }
        require(result, "Item not found");
    }

    function getBidHistories(uint256 id)
        external
        view
        returns (
            BidHistory[] memory bidHistories
        )
    {
        uint bidHistoryLength = itemsOnMarketBidHistories[id].length;
        require(0 < bidHistoryLength, "not auction item");
        bidHistories = itemsOnMarketBidHistories[id];
        return bidHistories;
    }
    
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}