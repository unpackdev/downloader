// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// By NightRabbit and nut4214

pragma solidity ^0.8.0;

import "./HoloNFT.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./SignatureChecker.sol";

contract MorpheusMarket is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;

    uint16 constant private MINIMUM_PRICE = 100;

    HoloNFT private holoNFTToken;
    mapping(uint256 => Trade) private trades; 
    mapping(address => uint256) private credits;

    enum TradeStatus {CLOSE, OPEN} 
    struct Trade {
        uint8 status;
        uint248 price;
    }

    event TradeStatusChange(uint256 tokenId, uint8 status, uint248 price);

    modifier forSaleTokenOnly(uint256 tokenId) {
        require(holoNFTToken.isTokenExist(tokenId), "Morpheus Market: Token ID does not exist");
        require(trades[tokenId].status == uint8(TradeStatus.OPEN), "Morpheus Market: The token is not for sale.");
        _;
    }

    modifier tokenOwnerOnly(uint256 tokenId) {
        require(_msgSender() == holoNFTToken.ownerOf(tokenId), "Morpheus Market: Sender is not the owner of this token.");
        _;
    }

    constructor(HoloNFT itemTokenAddress) {
        require(address(itemTokenAddress) != address(0), "Morpheus Market: HoloNFT is NULL");
        holoNFTToken = itemTokenAddress;
    }

    // ************************************************
    // For a Token owner only
    // ************************************************

    function openTrade(uint256 tokenId, uint248 newPrice) public tokenOwnerOnly(tokenId) nonReentrant {

        require(newPrice >= MINIMUM_PRICE, "Morpheus Market: Token price is less than or equal to zero.");

        trades[tokenId] = Trade({
            status: uint8(TradeStatus.OPEN),
            price: newPrice
        });

        emit TradeStatusChange(tokenId, uint8(TradeStatus.OPEN), newPrice);
    }

    function cancelTrade(uint256 tokenId) public tokenOwnerOnly(tokenId) nonReentrant {

        require(trades[tokenId].status != uint8(TradeStatus.CLOSE), "Morpheus Market: This token is already not for sale.");

        trades[tokenId] = Trade({status: uint8(TradeStatus.CLOSE), price: 0});
        emit TradeStatusChange(tokenId, uint8(TradeStatus.CLOSE), 0);
    }

    // ************************************************
    // Public functions
    // ************************************************

    function getTrade(uint256 tokenId) public view forSaleTokenOnly(tokenId) returns (uint8, uint248) {
        return (trades[tokenId].status, trades[tokenId].price);
    }

    function withdrawCredits() external nonReentrant{

        uint256 amount = credits[_msgSender()];

        require(amount != 0, "The caller does not have any credit");
        require(address(this).balance >= amount, "No money in the contract");

        credits[_msgSender()] = 0;
        payable(_msgSender()).transfer(amount);
    }

    // ************************************************
    // For selling token only
    // ************************************************

    function executeTrade(uint256 tokenId, bytes32 signature) external payable forSaleTokenOnly(tokenId) nonReentrant {

        uint248 tokenPrice = trades[tokenId].price;
        address payable seller = payable(address(holoNFTToken.ownerOf(tokenId))); 
        address payable creator =  payable(address(holoNFTToken.getCreatorAddress(tokenId))); 
        address payable publisher = payable(address(holoNFTToken.getPublisherFeeCollectorAddress())); 
        uint16 tokenCreatorFee = holoNFTToken.getCreatorFee(tokenId);
        uint16 publisherFee = holoNFTToken.getPublisherFee(tokenId);
        bool isAllowSignature = holoNFTToken.isAllowSignature(tokenId);

        _transferRevenue(tokenPrice, seller, creator, tokenCreatorFee, publisher, publisherFee);

        if(isAllowSignature){
            holoNFTToken.safeTransferFromWithSignature(seller, msg.sender, tokenId, signature);
        }
        else{
            holoNFTToken.safeTransferFrom(seller, msg.sender, tokenId);
        }
        
        trades[tokenId] = Trade({
            status: uint8(TradeStatus.CLOSE),
            price: 0
        });

        emit TradeStatusChange(tokenId, uint8(TradeStatus.CLOSE), 0);
    }

    // ************************************************
    // Lazy minting functions
    // ************************************************

    function purchaseAndMintHoloNFT(
        uint248 sellingPrice,
        uint256 tokenId,
        address payable creator,
        uint16 creatorFee,
        bool allowSignature,
        bytes32 creatorSignature,
        bytes32 buyerSignature,
        uint16 publisherFee,
        uint16 publisherFeeFirstSale,
        bytes calldata publisherSignature
    ) public payable nonReentrant {

        bytes32 digest =
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        sellingPrice,
                        tokenId,
                        creator,
                        creatorFee,
                        allowSignature,
                        creatorSignature,
                        publisherFee,
                        publisherFeeFirstSale
                    )
                )
            );

        require(sellingPrice >= MINIMUM_PRICE, "Morpheus Market: Token price is less than or equal to zero.");
        require(_verifySignature(digest, publisherSignature), "Morpheus Market: Invalid signature");

        address payable publisher = payable(address(holoNFTToken.getPublisherFeeCollectorAddress()));
        _transferRevenue(sellingPrice, creator, creator, creatorFee, publisher, publisherFeeFirstSale);

        holoNFTToken.lazyMintTo(
            payable(address(_msgSender())),
            tokenId,
            creator,
            creatorFee,
            allowSignature,
            creatorSignature,
            buyerSignature,
            publisherFee
        );

        trades[tokenId] = Trade({
            status: uint8(TradeStatus.CLOSE),
            price: 0
        });
    }

    function redeemHoloNFTDrop(
        address payable to,
        uint256 tokenId,
        address payable creator,
        uint16 creatorFee,
        bool allowSignature,
        bytes32 creatorSignature,
        bytes32 buyerSignature,
        uint16 publisherFee,
        bytes calldata publisherSignature
    ) public nonReentrant{

        bytes32 digest =
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        to,
                        tokenId,
                        creator,
                        creatorFee,
                        allowSignature,
                        creatorSignature,
                        publisherFee
                    )
                )
            );

        require(_verifySignature(digest, publisherSignature), "Morpheus Market: Invalid signature");

        holoNFTToken.lazyMintTo(
            to,
            tokenId,
            creator,
            creatorFee,
            allowSignature,
            creatorSignature,
            buyerSignature,
            publisherFee
        );

        trades[tokenId] = Trade({
            status: uint8(TradeStatus.CLOSE),
            price: 0
        });
    }

    // ************************************************
    // Private functions
    // ************************************************

    function _verifySignature(bytes32 digest, bytes memory signature) private view returns (bool){
        address signer = ECDSA.recover(digest, signature);

        if(signer == owner()){
            return true;
        }
            
        if(holoNFTToken.isOperator(signer)){
            return true;
        }
        
        return false;
    }

    function _transferRevenue(
        uint248 tokenPrice,
        address payable seller,
        address payable creator,
        uint16 creatorFee,
        address payable publisher,
        uint16 publisherFee
    ) private {

        require(tokenPrice > 0, "Morpheus Market: tokenPrice > 0"); 
        require(msg.value >= tokenPrice, "Morpheus Market: msg.value is lower"); 
        require(seller != address(0), "Morpheus Market: Seller address is 0x00"); 
        require(creator != address(0), "Morpheus Market: Creator address is 0x00");
        require(publisher != address(0), "Morpheus Market: Publisher address is 0x00");

        uint256 creatorAmount = msg.value.mul(creatorFee).div(10000);
        uint256 publisherAmount = msg.value.mul(publisherFee).div(10000);
        uint256 sellerAmount = msg.value.sub(creatorAmount).sub(publisherAmount);

        assert(creatorAmount.add(publisherAmount).add(sellerAmount) == msg.value);

        if(creator == seller){
            sellerAmount = sellerAmount.add(creatorAmount);
            creatorAmount = 0;
        }

        if (creatorFee != 0) {
            if (!creator.send(creatorAmount)) {
                credits[creator] += creatorAmount;
            }
        }

        if (publisherFee != 0) {
            if (!publisher.send(publisherAmount)) {
                credits[publisher] += publisherAmount;
            }
        }

        if (!seller.send(sellerAmount)) {
            credits[seller] += sellerAmount;
        }

    }

}
