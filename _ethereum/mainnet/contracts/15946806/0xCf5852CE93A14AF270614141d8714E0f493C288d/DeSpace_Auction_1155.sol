// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./DeSpace_Container_1155.sol";

abstract contract DeSpace_Auction_1155 is DeSpace_Container_1155 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public aucIds;
    mapping(uint256 => Auction) private _auctions;
    event AuctionCreated(address indexed seller, uint256 indexed aucId);
    event CancelledAuction(uint256 indexed id);
    event FulfilledAuction(
        address indexed topBidder,
        uint256 indexed aucId,
        uint256 topBid
    );
    event NewBid(address indexed bidder, uint256 indexed aucId, uint256 price);
    event UpdatedAuction(
        address indexed seller,
        uint256 indexed aucId,
        uint256 endTimestamp
    );

    //Modifier to check all conditions are met before bid
    modifier bidIf(uint256 _aucId) {
        Auction memory auction;
        auction = _auctions[_aucId];

        if (auction.seller == address(0))
            revert DeSpace_Marketplace_NonExistent();
        if (auction.seller == msg.sender) revert DeSpace_Marketplace_BidOwn();
        if (auction.fixedTime) {
            if (auction.startPeriod > block.timestamp)
                revert DeSpace_Marketplace_NotStarted();
            if (auction.endPeriod <= block.timestamp)
                revert DeSpace_Marketplace_AlreadyEnded();
        } else {
            if (auction.closed) {
                revert DeSpace_Marketplace_AlreadyEnded();
            }
        }
        _;
    }

    function listAuction(
        address _from,
        address _token,
        uint256 _tokenId,
        uint256 _numberOfTokens,
        uint256 _floorPrice,
        uint256 _startsInHowManySeconds,
        uint256 _duration,
        bool _fixedTime,
        MoneyType money
    ) external returns (uint256 aucId) {
        if (_floorPrice == 0) revert DeSpace_Marketplace_PriceCheck();

        _checkBeforeCollect(_from, _token, _tokenId, _numberOfTokens);

        uint256 startsIn = block.timestamp + _startsInHowManySeconds;
        uint256 period = startsIn + _duration;

        aucIds++;
        aucId = aucIds;

        _auctions[aucId] = Auction(
            payable(msg.sender),
            payable(address(0)),
            _token,
            _tokenId,
            _numberOfTokens,
            _floorPrice,
            0,
            startsIn,
            period,
            0,
            money,
            false,
            _fixedTime
        );

        emit AuctionCreated(msg.sender, aucId);
    }

    function bid(uint256 _aucId, uint256 amount)
        external
        payable
        bidIf(_aucId)
        nonReentrant
    {
        Auction memory auction = _auctions[_aucId];
        Auction storage atn = _auctions[_aucId];
        uint256 amt = _amountForNextBid(_aucId);

        if (auction.money == MoneyType.DES) {
            if (msg.value != 0) revert DeSpace_Marketplace_WrongAsset();
            if (amount < amt) revert DeSpace_Marketplace_PriceCheck();

            IERC20Upgradeable des_ = IERC20Upgradeable(des);
            des_.safeTransferFrom(msg.sender, address(this), amount);

            if (auction.bidCount != 0)
                des_.safeTransfer(auction.topBidder, auction.topBid);

            atn.topBidder = payable(msg.sender);
            atn.topBid = amount;
        } else {
            if (msg.value < amt) revert DeSpace_Marketplace_PriceCheck();
            if (auction.bidCount != 0)
                auction.topBidder.transfer(auction.topBid);

            atn.topBidder = payable(msg.sender);
            atn.topBid = msg.value;
        }

        atn.bidCount++;
        emit NewBid(msg.sender, _aucId, amount);
    }

    function closeAuction(uint256 _aucId) external nonReentrant {
        Auction memory auction = _auctions[_aucId];

        (, uint256 timeLeft, bool isFixedTime) = _timeLeftForBid(_aucId);

        if (!isFixedTime) {
            if (msg.sender != auction.seller || msg.sender != owner()) {
                revert DeSpace_Marketplace_UnauthorizedCaller();
            }
        } else {
            if (timeLeft != 0) {
                revert DeSpace_Marketplace_WrongCallPeriod();
            }
        }

        IERC1155Upgradeable nft = IERC1155Upgradeable(auction.token);
        if (auction.topBid == 0) {
            //not sold
            nft.safeTransferFrom(
                address(this),
                auction.seller,
                auction.tokenId,
                auction.numberOfTokens,
                "0x0"
            );
            emit CancelledAuction(_aucId);
        } else {
            //sold
            uint256 fee;
            if (auction.money == MoneyType.DES) {
                fee = (desFee * auction.topBid) / DIV;
                IERC20Upgradeable des_ = IERC20Upgradeable(des);
                des_.safeTransfer(wallet, fee);
                des_.safeTransfer(auction.seller, auction.topBid - fee);
            } else {
                fee = (nativeFee * auction.topBid) / DIV;
                wallet.transfer(fee);
                auction.seller.transfer(auction.topBid - fee);
            }

            nft.safeTransferFrom(
                address(this),
                auction.topBidder,
                auction.tokenId,
                auction.numberOfTokens,
                "0x0"
            );

            _auctions[_aucId].closed = true;
            emit FulfilledAuction(auction.topBidder, _aucId, auction.topBid);
        }
    }

    function updateAuctionEnd(
        uint256 _aucId,
        uint256 _endsIn,
        bool _fixedTime
    ) external {
        Auction storage auction;
        auction = _auctions[_aucId];

        if (auction.seller != msg.sender)
            revert DeSpace_Marketplace_UnauthorizedCaller();

        uint256 newTime = block.timestamp + _endsIn;
        auction.endPeriod = newTime;
        auction.fixedTime = _fixedTime;

        emit UpdatedAuction(msg.sender, _aucId, newTime);
    }

    function timeLeftForBid(uint256 _aucId)
        external
        view
        returns (
            uint256 startsIn,
            uint256 endsIn,
            bool isFixedTime
        )
    {
        return _timeLeftForBid(_aucId);
    }

    function amountForNextBid(uint256 _aucId)
        external
        view
        returns (uint256 amount)
    {
        return _amountForNextBid(_aucId);
    }

    function idToAuction(uint256 _aucId)
        external
        view
        returns (Auction memory)
    {
        return _auctions[_aucId];
    }

    function _timeLeftForBid(uint256 _aucId)
        private
        view
        returns (
            uint256 startsIn,
            uint256 endsIn,
            bool isFixedTime
        )
    {
        Auction memory auction = _auctions[_aucId];
        uint256 time = block.timestamp;

        if (auction.fixedTime) {
            auction.startPeriod > time
                ? startsIn = auction.startPeriod - time
                : startsIn = 0;

            auction.endPeriod > time
                ? endsIn = auction.endPeriod - time
                : endsIn = 0;

            isFixedTime = true;
        } else {
            return (0, 0, false);
        }
    }

    function _amountForNextBid(uint256 _aucId)
        private
        view
        returns (uint256 amount)
    {
        Auction memory auction;
        auction = _auctions[_aucId];

        if (auction.seller == address(0))
            revert DeSpace_Marketplace_NonExistent();
        if (auction.closed) return 0;
        if (auction.bidCount == 0) return auction.floorPrice;
        //10% of current highest bid
        else return ((auction.topBid * 10e4) / DIV) + auction.topBid;
    }
}
