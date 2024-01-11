// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;


import "Ownable.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";
import "IERC721Receiver.sol";
import "ERC1155Receiver.sol";

import "IMintywayRoyalty.sol";
import "TokenLibrary.sol";
import "LotLibrary.sol";

contract MintywayAuction is Ownable, IERC721Receiver, ERC1155Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using TokenLibrary for TokenLibrary.TokenValue;
    using LotLibrary for LotLibrary.Lot;

    event LotCreated(uint256 lotId);
    event AuctionCanceled(uint256 lotId);
    event BetPlaced(uint256 lotId, address buyer, uint256 newPrice);
    event AuctionFinished(uint256 lotId);

    modifier onlyLotOwner(uint256 lotId) {
        require(
            msg.sender == lots[lotId].owner,
            "BA: You are not the owner of lot"
        );
        _;
    }

    mapping(uint256 => LotLibrary.Lot) public lots;
    uint256 public nextLotId;
    mapping(IERC20 => uint256) public collectedFees;
    mapping(address => mapping(IERC20 => uint256)) public collectedRoyalties;
    uint32 internal _auctionFeeDenominator = 25; // 4% 
    uint256 internal _stepOfAuctionDenominator = 100;
    uint256 internal _timeOfAuction = 86400; // 24 hours 

    mapping(address => bool) private _supportsRoyalties;

    constructor(uint256 timeOfAuction_, address erc721Contract, address erc1155Contract) {
        _timeOfAuction = timeOfAuction_;
        _supportsRoyalties[erc721Contract] = true;
        _supportsRoyalties[erc1155Contract] = true;
    }

    function setContractWithRoyalties(address ercContract) external onlyOwner {
        _supportsRoyalties[ercContract] = true;
    }

    function isSupportRoyalties(address ercContract) external view returns(bool) {
        return _supportsRoyalties[ercContract];
    }
    
    function deleteContractWithRoyalties(address ercContract) external onlyOwner {
        _supportsRoyalties[ercContract] = false;
    }

    function setTimeOfAuction(uint256 newTimeOfAuction) external onlyOwner {
        _timeOfAuction = newTimeOfAuction;
    }

    function timeOfAuction() external view returns(uint256) {
        return _timeOfAuction;
    }

    function getLot(uint256 lotId) external view returns(LotLibrary.Lot memory) {
        return lots[lotId];
    }

    function setAuctionFeeDenominator(uint32 auctionFeeDenominator_) external onlyOwner {
        _auctionFeeDenominator = auctionFeeDenominator_;
    }
    
    function auctionFeeDenominator() external view returns(uint32) {
        return _auctionFeeDenominator;
    }

    function setStepOfAuctionDenominator(uint256 stepOfAuctionDenominator_) external onlyOwner {
        _stepOfAuctionDenominator = stepOfAuctionDenominator_;
    }

    function stepOfAuctionDenominator() external view returns(uint256) {
        return _stepOfAuctionDenominator;
    }

    function createAuction(
        TokenLibrary.TokenValue calldata token, 
        uint256 price, 
        IERC20 paymentContract
        ) public returns(uint256 lotId){

        address sender = msg.sender;

        require(price != 0, "MintywayAuction: Price of lot can not be zero");
        
        address creator;
        uint256 royalty;

        if (_supportsRoyalties[token.token]) {
            royalty = IMintywayRoyalty(token.token).royaltyOf(token.tokenId);
            creator = IMintywayRoyalty(token.token).creatorOf(token.tokenId);
        } 

        lots[nextLotId] = LotLibrary.Lot ({
            owner: sender,
            buyer: address(0),
            token: token,
            paymentContract: paymentContract,
            startTime: block.timestamp, // 86400 seconds (24 hours)
            time: _timeOfAuction,
            price: price, 
            status: LotLibrary.LotStatus.FOR_AUCTION,
            royalty: royalty,
            creator: creator
        });

        lots[nextLotId].transferToken(sender, address(this));

        emit LotCreated(nextLotId);
        nextLotId++;
        return(nextLotId-1);
    }
    

    function cancelAuction(uint256 lotId) public onlyLotOwner(lotId) nonReentrant {
        LotLibrary.Lot storage lot = lots[lotId];
        address sender = msg.sender;
        require(
            lot.status == LotLibrary.LotStatus.FOR_AUCTION,
            "MintywayAuction: Lot is not on auction"
        );
        
        lot.transferToken(address(this), sender);
        
        lot.status = LotLibrary.LotStatus.CANCELED;
        emit AuctionCanceled(lotId);
    }

    function placeBet(uint256 lotId, uint256 newPrice) external nonReentrant {
        address sender = msg.sender;
        LotLibrary.Lot storage lot = lots[lotId];
        
        require(sender != lot.buyer,
                "MintywayAuction: You have already placed a bet");
        require(
            lot.status == LotLibrary.LotStatus.FOR_AUCTION || lot.status == LotLibrary.LotStatus.WITH_BETS,
            "MintywayAuction: This lot is not on auction" 
        );
        require(
            lot.startTime + lot.time > block.timestamp || lot.buyer == address(0), 
            "MintywayAuction: Time has expired"
        );


        if (lot.buyer != address(0)) {

            require(newPrice >= lot.price + lot.price / _stepOfAuctionDenominator,
                "MintywayAuction: price is too low");

            lot.paymentContract.safeTransfer(
                lot.buyer,
                lot.price
            );

        } else {
            require(newPrice >= lot.price,
                "MintywayAuction: price is too low");
        }

        lot.price = newPrice;

        lot.paymentContract.safeTransferFrom(
            sender,
            address(this),
            lot.price
        );

        lot.buyer = sender;
        lot.status = LotLibrary.LotStatus.WITH_BETS;
        lot.startTime = block.timestamp;

        emit BetPlaced(lotId, lot.buyer, lot.price);
    }

    function finishAuction(uint256 lotId) external nonReentrant {
        address sender = msg.sender;
        LotLibrary.Lot storage lot = lots[lotId];

        require(
            lot.status == LotLibrary.LotStatus.WITH_BETS,
            "MintywayAuction: Auction is not finished or was canceled"
        );

        require(
            lot.startTime + lot.time < block.timestamp, "MintywayAuction: Time has not expired"
        );

        lot.transferToken(address(this), lot.buyer);

        uint256 fee = lot.price / _auctionFeeDenominator;
        uint256 royalty = 0;

        if (lot.royalty != 0) {
            royalty = lot.price * lot.royalty / 100;
            collectedRoyalties[lot.creator][lot.paymentContract] += royalty;

            lot.paymentContract.safeTransfer(
                lot.creator,
                royalty
            );
        }

        lot.paymentContract.safeTransfer(
            lot.owner,
            lot.price - fee - royalty
        );

        collectedFees[lot.paymentContract] += fee;

        lot.status = LotLibrary.LotStatus.WITHDRAWN;
        emit AuctionFinished(lotId);
    }

    function withdrawFees(IERC20 contractAddress) external onlyOwner {
        contractAddress.safeTransfer(owner(), collectedFees[contractAddress]);
        collectedFees[contractAddress] = 0;
    }

    function onERC721Received(address /* operator */, address /* from */, uint256 /* tokenId */, bytes calldata /* data */) override public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address /* operator */, address /* from */, uint256 /* id */, uint256 /* value */, bytes calldata /* data */) override public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address /* operator */, address /* from */, uint256[] calldata /* ids */, uint256[] calldata /* values */, bytes calldata /* data */) override public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}