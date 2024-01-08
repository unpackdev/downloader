pragma solidity >=0.6.2 <0.8.0;
import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

import "./Initializable.sol";
import "./Locker.sol";
import "./BaseMarket.sol";

contract AuctionMarket is Initializable, BaseMarket {
    using SafeMath for uint256;
    uint256 private _auctionId;
    uint256 private _minDuration;

    //[nft -> [tokenId -> auction]]
    address payable _locker;
    mapping(address => mapping(uint256 => Auction)) private _auctionsByNFTAndTokenID;
    mapping(uint256 => Auction) private _auctions;
    mapping(uint256 => Bid) private _bids;
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _lockingCurrencyBalance;

    struct Bid {
        uint256 auctionId;
        uint256 bidTime;
        address bidder;
        uint256 price;
        bool isClaimed;
        bool isExist;
    }
    struct Auction {
        uint256 auctionId;
        address payable seller;
        address nftAddr;
        uint256 tokenId;
        uint256 initPrice;
        uint256 startTime;
        uint256 duration;
        address currency;
        uint256 nftType;
        uint256 amount;
        bool isExist;
        bool isClaimed;
        address payable royaltyReceiver;
        uint256 royaltyFee;
    }

    /// @notice New auction has been made
    /// @dev New auction has been made
    /// @param tokenId - tokenId which will be sold
    /// @param seller - address of seller who make the auction
    /// @param nftAddr - address of NFT contract which will be sold
    /// @param initPrice - amount of initial price which is starting point of the auction
    /// @param currency - type of payment token which will be used in the auction
    /// @param startTime - when the auction will be started, buyers can bid
    /// @param duration - in which the auction is valid
    event AuctionEvt(
        uint256 auctionId,
        address seller,
        address nftAddr,
        uint256 tokenId,
        uint256 initPrice,
        uint256 startTime,
        uint256 duration,
        address currency
    );
    /// @notice New claim has been done (eg. claimer received currency or nft)
    /// @dev New claim has been done (eg. claimer received currency or nft)
    /// @param auctionId is auction which event is emitted
    /// @param sender is claimer
    /// @param value is amount of currency or tokenId of nft
    /// @param typeOfValue type of value (0: NFT, 1: Klay, 2: KIP7)
    event Claim(uint256 auctionId, address sender, uint256 value, uint256 typeOfValue);

    event TransferFee(uint256 auctionId, uint256 commissionFee, uint256 royaltyFee);

    /// @notice Event when new bid is successful
    /// @dev Event when new bid is successful
    /// @param auctionId is id of auction which bidder want bid
    /// @param bidder is the owner of bidding order
    /// @param price is the price of owner who made the bid
    /// @param biddingTime is the timestamp when the bid has been made
    event BidEvt(uint256 auctionId, address bidder, uint256 price, uint256 biddingTime);

    /// @notice Emitted when sale or auction has been canceled
    /// @dev Emitted when sale or auction has been canceled
    /// @param id id of fixed price sale or auction which has been canceled
    event AuctionCanceled(uint256 id);

    event AuctionUpdated(uint256 auctionId, uint256 initPrice, uint256 startTime, uint256 duration, address currency);

    /// @dev Initialize data when want use the nft market for trading. Should be called in proxy when upgrading the nft marketing
    /// @param startAuctionId - it is the first of id of sale when user make the sale order
    /// @param minDuration - it is min of duration in which the buying or bidding order is valid
    function initialize(
        uint256 startAuctionId,
        uint256 minDuration,
        address payable lockerAddr,
        address payable feeWallet,
        address owner
    ) public initializer {
        require(minDuration > 0, 'Min duration must be zero');
        require(startAuctionId >= 0, 'Start sale id must be greater than zero');
        _minDuration = minDuration;
        _auctionId = startAuctionId;
        _locker = lockerAddr;
        _commissionFee = 0;
        // _commissionFee = 50000; //precision is 6 decimals, 50000 = 5% = 0.05
        _feePrecision = 1e6;
        _feeWallet = feeWallet;
        _transferOwnership(owner);
    }

    /// @dev This function allows make a new auction.
    /// @notice Make an new auction
    /// @param tokenId - tokenId which will be sold
    /// @param nftAddr - address of NFT contract which will be sold
    /// @param initPrice - amount of initial price which is starting point of the auction
    /// @param currency - type of payment token which will be used in the auction
    /// @param startTime - when the auction will be started, buyers can bid
    function makeAuction721(
        uint256 tokenId,
        address nftAddr,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        address payable royaltyReceiver,
        uint256 royaltyFee,
        uint256 salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        Auction memory newAuction;
        newAuction.tokenId = tokenId;
        newAuction.nftAddr = nftAddr;
        newAuction.seller = msg.sender;
        newAuction.initPrice = initPrice;
        newAuction.startTime = startTime;
        newAuction.duration = duration;
        newAuction.currency = currency;
        newAuction.isClaimed = false;
        newAuction.isExist = true;
        newAuction.nftType = 0;
        newAuction.amount = 1;
        newAuction.royaltyReceiver = royaltyReceiver;
        newAuction.royaltyFee = royaltyFee;

        RoyaltySignature memory saleSign;
        saleSign.nftAddr = nftAddr;
        saleSign.r = r;
        saleSign.v = v;
        saleSign.s = s;
        saleSign.royaltyFee = royaltyFee;
        saleSign.royaltyReceiver = royaltyReceiver;
        saleSign.tokenId = tokenId;
        saleSign.salt = salt;
        return _makeAuction(newAuction, saleSign);
    }

    /// @dev This function allows make a new auction.
    /// @notice Make an new auction
    /// @param tokenId - tokenId which will be sold
    /// @param nftAddr - address of NFT contract which will be sold
    /// @param initPrice - amount of initial price which is starting point of the auction
    /// @param currency - type of payment token which will be used in the auction
    /// @param startTime - when the auction will be started, buyers can bid
    function makeAuction1155(
        uint256 tokenId,
        address nftAddr,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        uint256 amount,
        address payable royaltyReceiver,
        uint256 royaltyFee,
        uint256 salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        Auction memory newAuction;
        newAuction.tokenId = tokenId;
        newAuction.nftAddr = nftAddr;
        newAuction.seller = msg.sender;
        newAuction.initPrice = initPrice;
        newAuction.startTime = startTime;
        newAuction.duration = duration;
        newAuction.currency = currency;
        newAuction.isClaimed = false;
        newAuction.isExist = true;
        newAuction.nftType = 1;
        newAuction.amount = amount;
        newAuction.royaltyReceiver = royaltyReceiver;
        newAuction.royaltyFee = royaltyFee;

        RoyaltySignature memory saleSign;
        saleSign.nftAddr = nftAddr;
        saleSign.r = r;
        saleSign.v = v;
        saleSign.s = s;
        saleSign.royaltyFee = royaltyFee;
        saleSign.royaltyReceiver = royaltyReceiver;
        saleSign.tokenId = tokenId;
        saleSign.salt = salt;
        return _makeAuction(newAuction, saleSign);
    }

    function _makeAuction(Auction memory auctionInfo, RoyaltySignature memory saleSign) internal returns (uint256) {
        require(_checkRoyaltyFeeSignature(saleSign) == true, 'Invalid Signature');

        //make sure the owner of tokenId is sender
        require(auctionInfo.nftAddr != address(0x0), 'Invalid nft address');
        require(auctionInfo.nftType == 0 || auctionInfo.nftType == 1, 'Invalid nft type');
        if (auctionInfo.nftType == 0) {
            IERC721 nft = IERC721(auctionInfo.nftAddr);
            require(nft.ownerOf(auctionInfo.tokenId) == msg.sender, 'Not permission or Invalid token Id');
            require(nft.getApproved(auctionInfo.tokenId) == address(this), 'Need to be approved');
            nft.safeTransferFrom(msg.sender, _locker, auctionInfo.tokenId);
        } else {
            IERC1155 nft = IERC1155(auctionInfo.nftAddr);
            require(nft.balanceOf(msg.sender, auctionInfo.tokenId) >= auctionInfo.amount, 'Invalid amount');
            require(nft.isApprovedForAll(msg.sender, address(this)), 'Market need permission on NFTs');
            nft.safeTransferFrom(msg.sender, _locker, auctionInfo.tokenId, auctionInfo.amount, '');
        }

        //validates price, currency, startTime, endTime
        require(auctionInfo.initPrice > 0, 'Price must be greater then zero');
        // require(currency != address(0x0), 'Invalid currency');
        require(auctionInfo.startTime > block.timestamp, 'Starttime must be after now');
        require(auctionInfo.duration > _minDuration, 'Duration must be equal or greater than min duration');
        //make sure the NFT is not in any sale
        require(
            _auctionsByNFTAndTokenID[auctionInfo.nftAddr][auctionInfo.tokenId].isExist == false,
            'Item is in sold already'
        );

        require(auctionInfo.amount > 0, 'Invalid amount');

        //make new auction
        _auctionId++;
        uint256 auctionId = _auctionId;

        auctionInfo.auctionId = auctionId;

        //store auction data
        _auctionsByNFTAndTokenID[auctionInfo.nftAddr][auctionInfo.tokenId] = auctionInfo;
        _auctions[auctionId] = auctionInfo;

        //emit event
        emit AuctionEvt(
            auctionInfo.auctionId,
            auctionInfo.seller,
            auctionInfo.nftAddr,
            auctionInfo.tokenId,
            auctionInfo.initPrice,
            auctionInfo.startTime,
            auctionInfo.duration,
            auctionInfo.currency
        );
        return auctionInfo.auctionId;
    }

    /// @dev Make a bid to auction when want to buy the item
    /// @param auctionId - id of auction in which wanted item is listed
    /// @param price - amount of payment token which allowed in the auction, you can pay to buy the item. this is amount of locked amount.
    /// @return true - bid order is successful, bid order is failed
    function bid(uint256 auctionId, uint256 price) external payable returns (bool) {
        //Make sure update klay of sender
        if (msg.value > 0) {
            //update klay sent to contract
            _lockingCurrencyBalance[address(0x0)][msg.sender][auctionId] = _lockingCurrencyBalance[address(0x0)][
                msg.sender
            ][auctionId].add(msg.value);
        }
        //check the auctionId is existed
        require(_auctions[auctionId].isExist == true, 'Not found auction');
        Auction memory auction;
        auction = _auctions[auctionId];

        require(msg.sender != auction.seller, 'Buyer/Seller must be different');
        //make sure it is in duration of auction
        require(block.timestamp >= auction.startTime, 'Auction is not started');
        require(block.timestamp <= auction.startTime.add(auction.duration), 'Bid must be in auction time');

        //must be equal or greater than init price
        require(auction.initPrice <= price, 'Bid must be equal or greater than init price');
        //make sure the price of current bid is greater than the previous highest bid
        uint256 hightestPrice = _bids[auctionId].price;
        require(hightestPrice < price, 'New bid must be greater than previous highest bids');

        //make sure the locking amount of the currency of buyer (msg.sender) is equal to price of the bid
        uint256 lockingAmount = _lockingCurrencyBalance[auction.currency][msg.sender][auctionId];

        if (lockingAmount < price) {
            //need to lock more amount of currency to make sure the bid become valid
            uint256 lockingAmountDelta = price.sub(lockingAmount);
            //auction by KIP7
            IERC20 currency = IERC20(auction.currency);
            //check msg.owner (bidder) has allow the NFT market contract permission to lock the price in the bid
            require(
                currency.allowance(msg.sender, address(this)) >= lockingAmountDelta,
                'Buyer need allow the contract lock their bid price'
            );
            //check msg.owner have enough balance of auction currency
            require(currency.balanceOf(msg.sender) >= lockingAmountDelta, 'Not enough price');
            currency.transferFrom(msg.sender, _locker, lockingAmountDelta);
            _lockingCurrencyBalance[auction.currency][msg.sender][auctionId] = price;
        }

        //update new hightest bid
        Bid memory newHightestBid;
        newHightestBid.auctionId = auctionId;
        newHightestBid.bidder = msg.sender;
        newHightestBid.bidTime = block.timestamp;
        newHightestBid.price = price;
        newHightestBid.isClaimed = false;
        newHightestBid.isExist = true;
        _bids[auctionId] = newHightestBid;
        emit BidEvt(newHightestBid.auctionId, newHightestBid.bidder, newHightestBid.price, newHightestBid.bidTime);

        return true;
    }

    /// @dev Require transfer the item to `msg.sender` if the `msg.sender` is the winner of `auctionId`.
    /// @param auctionId - id of auction which contains the item `msg.sender` win
    /// @return true - claim is successful, false - claim is failed
    function claimAuction(uint256 auctionId) external returns (bool) {
        // Locker locker = Locker(_locker);
        //make sure the auctionId is valid
        require(_auctions[auctionId].isExist == true, 'Not found auction');
        Auction memory auction;
        auction = _auctions[auctionId];
        //make sure the auction is stop
        require(auction.startTime.add(auction.duration) < block.timestamp, 'Auction had been not stopped yet');
        //check the claimer whether is buyer or seller
        if (auction.seller == msg.sender) {
            _claimForSeller(auction);
        } else {
            _claimForBidder(auction);
        }

        return true;
    }

    /// @dev Call it when claimer is seller (only for auction)
    /// @param auction contains information of auction
    function _claimForSeller(Auction memory auction) private {
        Locker locker = Locker(_locker);
        uint256 auctionId = auction.auctionId;
        require(auction.isClaimed == false, 'Duplicate claim');
        //check there is bid for the auction
        if (_bids[auctionId].isExist == false) {
            //transfer the nft back to seller if there is no bid
            locker.transferNFT(msg.sender, auction.nftAddr, auction.tokenId, auction.nftType, auction.amount);
            emit Claim(auction.auctionId, msg.sender, auction.tokenId, 0);
        } else {
            //transfer the currency to seller if there is a bid

            Bid memory highestBid = _bids[auctionId];

            (uint256 returnAmount, uint256 commissionAmount, uint256 royaltyAmount) = _computeFee(
                highestBid.price,
                auction.royaltyFee
            );

            if (commissionAmount > 0) {
                if (auction.currency == address(0x0)) {
                    _feeWallet.transfer(commissionAmount);
                } else {
                    locker.transferCurrency(_feeWallet, auction.currency, commissionAmount);
                }
            }

            if (royaltyAmount > 0) {
                if (auction.currency == address(0x0)) {
                    auction.royaltyReceiver.transfer(royaltyAmount);
                } else {
                    locker.transferCurrency(auction.royaltyReceiver, auction.currency, royaltyAmount);
                }
            }
            emit TransferFee(auctionId, commissionAmount, royaltyAmount);
            _claimCurrency(auctionId, msg.sender, auction.currency, returnAmount);
        }
        _auctions[auctionId].isClaimed = true;
    }

    /// @dev Call it when the claimer of auction is bidder
    /// @param auction contains information of auction
    function _claimForBidder(Auction memory auction) private {
        Locker locker = Locker(_locker);
        uint256 auctionId = auction.auctionId;
        //check msg.sender is winner or not
        require(_bids[auctionId].isExist == true, 'No bid for auction, can not claim as buyer');
        Bid memory highestBid = _bids[auctionId];
        if (highestBid.bidder == msg.sender) {
            //check duplicate claim
            require(highestBid.isClaimed == false, 'Duplicated claim');
            //msg.sender is winner

            locker.transferNFT(highestBid.bidder, auction.nftAddr, auction.tokenId, auction.nftType, auction.amount);

            _bids[auctionId].isClaimed = true;
            emit Claim(auction.auctionId, msg.sender, auction.tokenId, 0);

            //stake more currency than highest price. should return the reminding amount.
            //happend only when auction by Klay
            if (auction.currency == address(0x0)) {
                if (_lockingCurrencyBalance[auction.currency][msg.sender][auctionId] > highestBid.price) {
                    uint256 returnAmount = _lockingCurrencyBalance[auction.currency][msg.sender][auctionId] -
                        highestBid.price;
                    _claimCurrency(auctionId, msg.sender, auction.currency, returnAmount);
                }
            }
        } else {
            //not winner, try to check the msg.sender whether is bidder
            //return locking amount
            uint256 lockAmount = _lockingCurrencyBalance[auction.currency][msg.sender][auctionId];
            require(lockAmount > 0, 'No bid');
            _claimCurrency(auction.auctionId, msg.sender, auction.currency, lockAmount);
            delete _lockingCurrencyBalance[auction.currency][msg.sender][auctionId];
        }
    }

    /// @dev Call when return the amount of currency to `to` who are bidder or seller of the auction
    /// @param auctionId Id of auction which the `to` want to claim. Which will be used to emit the event
    /// @param to address which will receive the currency
    /// @param currency is type of currency will need to send to `to`
    /// @param amount is amount of currency transferred to `to`
    function _claimCurrency(
        uint256 auctionId,
        address payable to,
        address currency,
        uint256 amount
    ) private {
        uint256 t = 1;
        if (currency == address(0x0)) {
            to.transfer(amount);
        } else {
            t = 2;
            Locker locker = Locker(_locker);
            locker.transferCurrency(msg.sender, currency, amount);
        }
        emit Claim(auctionId, to, amount, t);
    }

    /// @notice Emitted when sale or auction has been canceled
    /// @dev Emitted when sale or auction has been canceled
    /// @param auctionId auctionId of auction which has been canceled
    function cancel(uint256 auctionId) external returns (bool) {
        require(_auctions[auctionId].isExist == true, 'Aucton is not existed');
        require(_auctions[auctionId].seller == msg.sender, 'No permission');
        require(_bids[auctionId].isExist == false, 'Can not cancel when there are bids');

        Locker locker = Locker(_locker);
        locker.transferNFT(
            _auctions[auctionId].seller,
            _auctions[auctionId].nftAddr,
            _auctions[auctionId].tokenId,
            _auctions[auctionId].nftType,
            _auctions[auctionId].amount
        );

        delete _auctions[auctionId];

        emit AuctionCanceled(auctionId);
        return true;
    }

    function _updateAuction(
        uint256 auctionId,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        uint256 sellAmount
    ) private returns (bool) {
        require(_auctions[auctionId].isExist == true, 'Aucton is not existed');
        Auction memory auction = _auctions[auctionId];
        require(auction.seller == msg.sender, 'Sender is not permission');
        require(_bids[auctionId].isExist == false, 'Can not update when there are bids');
        require(auction.initPrice > 0, 'Price must be greater than zero');
        require(startTime > block.timestamp, 'Starttime must be after now');
        require(duration > _minDuration, 'Duration must be equal or greater than min duration');
        require(sellAmount > 0, 'Invalid amount');
        if (auction.nftType == 1 && sellAmount != auction.amount) {
            if (sellAmount > auction.amount) {
                uint256 delta = sellAmount - auction.amount;
                IERC1155 nft = IERC1155(auction.nftAddr);
                require(nft.balanceOf(msg.sender, auction.tokenId) >= delta, 'Invalid amount');
                require(nft.isApprovedForAll(msg.sender, address(this)), 'Market need permission on NFTs');
                nft.safeTransferFrom(msg.sender, _locker, auction.tokenId, delta, '');
            } else {
                uint256 delta = auction.amount - sellAmount;
                Locker locker = Locker(_locker);
                locker.transferNFT(auction.seller, auction.nftAddr, auction.tokenId, auction.nftType, delta);
            }
        }
        auction.currency = currency;
        auction.initPrice = initPrice;
        auction.duration = duration;
        auction.startTime = startTime;
        auction.amount = sellAmount;
        _auctionsByNFTAndTokenID[auction.nftAddr][auction.tokenId] = auction;
        _auctions[auctionId] = auction;

        emit AuctionUpdated(auctionId, auction.initPrice, auction.startTime, auction.duration, auction.currency);
        return true;
    }

    function updateAuction721(
        uint256 auctionId,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration
    ) external returns (bool) {
        return _updateAuction(auctionId, initPrice, currency, startTime, duration, 1);
    }

    function updateAuction1155(
        uint256 auctionId,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        uint256 sellAmount
    ) external returns (bool) {
        return _updateAuction(auctionId, initPrice, currency, startTime, duration, sellAmount);
    }

    function getAuction(uint256 auctionId)
        external
        view
        returns (
            uint256 id,
            address seller,
            address nftAddr,
            uint256 tokenId,
            uint256 initPrice,
            uint256 startTime,
            uint256 duration,
            address currency,
            uint256 nftType,
            uint256 amount,
            address royaltyReceiver,
            uint256 royaltyFee,
            bool isClaimed
        )
    {
        id = _auctions[auctionId].auctionId;
        seller = _auctions[auctionId].seller;
        nftAddr = _auctions[auctionId].nftAddr;
        tokenId = _auctions[auctionId].tokenId;
        initPrice = _auctions[auctionId].initPrice;
        startTime = _auctions[auctionId].startTime;
        duration = _auctions[auctionId].duration;
        currency = _auctions[auctionId].currency;
        nftType = _auctions[auctionId].nftType;
        amount = _auctions[auctionId].amount;
        royaltyReceiver = _auctions[auctionId].royaltyReceiver;
        royaltyFee = _auctions[auctionId].royaltyFee;
        isClaimed = _auctions[auctionId].isClaimed;
    }

    function getHighestBid(uint256 auctionId)
        external
        view
        returns (
            uint256 id,
            uint256 price,
            address bidder,
            uint256 bidTime
        )
    {
        id = auctionId;
        price = _bids[auctionId].price;
        bidder = _bids[auctionId].bidder;
        bidTime = _bids[auctionId].bidTime;
    }
}
