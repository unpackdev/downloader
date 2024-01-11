// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ECDSA.sol";
import "./IFinalizeAuctionController.sol";
import "./EnglishAuctionStorage.sol";
import "./EIP712.sol";
import "./SafeEthSender.sol";

contract EnglishAuction is EnglishAuctionStorage, SafeEthSender, EIP712 {
    bytes32 immutable BID_TYPEHASH =
        keccak256("Bid(uint32 auctionId,address bidder,uint256 value)");

    event AuctionCreated(uint32 auctionId);
    event AuctionCanceled(uint32 auctionId);
    event AuctionCanceledByAdmin(uint32 auctionId, string reason);
    event AuctionFinalized(uint32 auctionId, uint256 auctionBalance);
    event AuctionBidPlaced(uint32 auctionId, address bidder, uint256 amount);

    constructor(
        address _accessManangerAddress,
        address payable _withdrawalAddress
    ) EIP712("Place Bid", "1") {
        accessManager = IAccessManager(_accessManangerAddress);
        withdrawalAddress = _withdrawalAddress;
        initializeAuction();
    }

    modifier isOperationalAddress() {
        require(
            accessManager.isOperationalAddress(msg.sender) == true,
            "English Auction: You are not allowed to use this function"
        );
        _;
    }

    function setWithdrawalAddress(address payable _newWithdrawalAddress)
        public
        isOperationalAddress
    {
        withdrawalAddress = _newWithdrawalAddress;
    }

    function createAuction(
        uint32 _tokenId,
        uint32 _timeStart,
        uint32 _timeEnd,
        uint8 _minBidPercentage,
        uint256 _initialPrice,
        uint256 _minBidValue,
        address _nftContractAddress,
        address _finalizeAuctionControllerAddress,
        bytes memory _additionalDataForFinalizeAuction
    ) public isOperationalAddress {
        require(
            _initialPrice > 0,
            "English Auction: Initial price have to be bigger than zero"
        );

        uint32 currentAuctionId = incrementAuctionId();
        auctionIdToAuction[currentAuctionId] = AuctionStruct(
            _tokenId,
            _timeStart,
            _timeEnd,
            _minBidPercentage,
            _initialPrice,
            _minBidValue,
            0, //auctionBalance
            _nftContractAddress,
            _finalizeAuctionControllerAddress,
            payable(address(0)),
            _additionalDataForFinalizeAuction
        );

        emit AuctionCreated(currentAuctionId);
    }

    function incrementAuctionId() private returns (uint32) {
        return lastAuctionId++;
    }

    /**
     * @notice Returns auction details for a given auctionId.
     */
    function getAuction(uint32 _auctionId)
        public
        view
        returns (AuctionStruct memory)
    {
        return auctionIdToAuction[_auctionId];
    }

    function initializeAuction() private {
        lastAuctionId = 1;
    }

    function placeBid(uint32 _auctionId, bytes memory _signature)
        public
        payable
    {
        placeBid(_auctionId, _signature, msg.sender);
    }

    function placeBid(
        uint32 _auctionId,
        bytes memory _signature,
        address _bidder
    ) public payable {
        bytes32 _hash = _hashTypedDataV4(
            keccak256(abi.encode(BID_TYPEHASH, _auctionId, _bidder, msg.value))
        );
        address recoverAddress = ECDSA.recover(_hash, _signature);

        require(
            accessManager.isOperationalAddress(recoverAddress) == true,
            "Incorrect bid permission signature"
        );

        AuctionStruct storage auction = auctionIdToAuction[_auctionId];

        require(auction.initialPrice > 0, "English Auction: Auction not found");

        if (auction.timeStart == 0) {
            auction.timeStart = uint32(block.timestamp);
            auction.timeEnd += auction.timeStart;
        }

        require(
            auction.timeStart <= block.timestamp,
            "English Auction: Auction is not active yet"
        );

        require(
            auction.timeEnd > block.timestamp,
            "English Auction: Auction has been finished"
        );

        uint256 requiredBalance = auction.auctionBalance == 0
            ? auction.initialPrice
            : auction.auctionBalance + auction.minBidValue;

        uint256 requiredPercentageValue = (auction.auctionBalance *
            (auction.minBidPercentage + 100)) / 100;

        require(
            msg.value >= requiredBalance &&
                msg.value >= requiredPercentageValue,
            "English Auction: Bid amount was too low"
        );

        uint256 prevBalance = auction.auctionBalance;
        address payable prevBidder = auction.bidder;

        auction.bidder = payable(_bidder);
        auction.auctionBalance = msg.value;
        if ((auction.timeEnd - uint32(block.timestamp)) < 15 minutes) {
            auction.timeEnd = uint32(block.timestamp) + 15 minutes;
        }

        if (prevBalance > 0) {
            sendEthWithLimitedGas(prevBidder, prevBalance, 2300);
        }
        emit AuctionBidPlaced(_auctionId, _bidder, msg.value);
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeAuction(uint32 _auctionId) external {
        AuctionStruct memory auction = auctionIdToAuction[_auctionId];

        uint256 auctionBalance = auction.auctionBalance;

        require(auction.timeEnd > 0, "English Auction: Auction not found");

        require(
            auction.timeEnd <= block.timestamp,
            "English Auction: Auction is still in progress"
        );

        IFinalizeAuctionController finalizeAuctionController = IFinalizeAuctionController(
                auction.finalizeAuctionControllerAddress
            );

        (bool success, ) = auction
            .finalizeAuctionControllerAddress
            .delegatecall(
                abi.encodeWithSelector(
                    finalizeAuctionController.finalize.selector,
                    _auctionId
                )
            );

        require(success, "FinalizeAuction: DelegateCall failed");

        delete auctionIdToAuction[_auctionId];

        emit AuctionFinalized(_auctionId, auctionBalance);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     */
    function cancelAuction(uint32 _auctionId) external {
        AuctionStruct memory auction = auctionIdToAuction[_auctionId];

        IFinalizeAuctionController finalizeAuctionController = IFinalizeAuctionController(
                auction.finalizeAuctionControllerAddress
            );

        (bool success, ) = auction
            .finalizeAuctionControllerAddress
            .delegatecall(
                abi.encodeWithSelector(
                    finalizeAuctionController.cancel.selector,
                    _auctionId
                )
            );

        require(success, "CancelAuction: DelegateCall failed");

        delete auctionIdToAuction[_auctionId];

        emit AuctionCanceled(_auctionId);
    }

    /**
     * @notice Allows Nifties to cancel an auction, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    function adminCancelAuction(uint32 _auctionId, string memory _reason)
        public
        isOperationalAddress
    {
        AuctionStruct memory auction = auctionIdToAuction[_auctionId];

        IFinalizeAuctionController finalizeAuctionController = IFinalizeAuctionController(
                auction.finalizeAuctionControllerAddress
            );

        (bool success, ) = auction
            .finalizeAuctionControllerAddress
            .delegatecall(
                abi.encodeWithSelector(
                    finalizeAuctionController.adminCancel.selector,
                    _auctionId,
                    _reason
                )
            );

        require(success, "AdminCancelAuction: DelegateCall failed");

        if (auction.bidder != address(0)) {
            uint256 bidderAmount = auction.auctionBalance;
            auction.auctionBalance -= auction.auctionBalance;

            sendEthWithLimitedGas(auction.bidder, bidderAmount, 2300);
        }

        delete auctionIdToAuction[_auctionId];

        emit AuctionCanceledByAdmin(_auctionId, _reason);
    }
}
