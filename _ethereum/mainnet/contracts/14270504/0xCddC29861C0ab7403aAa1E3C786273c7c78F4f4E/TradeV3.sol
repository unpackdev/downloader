// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ITransferProxy.sol";

import "./IRoyaltyAwareNFT.sol";

/// @title TradeV3
///
/// @dev This contract is not an upgrade, is a new version of Trade contract. It has a new feature to allow buy assets
///      using native token.

contract TradeV3 is ReentrancyGuard {
    using SafeMath for uint256;

    enum BuyingAssetType { ERC1155, ERC721 }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event ExecuteBid(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity, address indexed buyer);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;
    ITransferProxy public transferProxy;
    address public owner;
    address public enigmaNFT721Address;
    address public enigmaNFT1155Address;

    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royaltyFee;
        uint256 price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        enigmaNFT721Address = _enigmaNFT721Address;
        enigmaNFT1155Address = _enigmaNFT1155Address;
        owner = msg.sender;
    }

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns (bool) {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns (bool) {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function ownerTransfership(address newOwner) external onlyOwner returns (bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns (address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s);
    }

    function verifySellerSignature(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount));
        require(seller == getSigner(hash, sign), "seller sign verification failed");
    }

    function verifyBuyerSignature(
        address buyer,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 qty,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, qty));
        require(buyer == getSigner(hash, sign), "buyer sign verification failed");
    }

    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId
    ) internal view returns (Fee memory) {
        address tokenCreator;
        uint256 platformFee;
        uint256 royaltyFee;
        uint256 assetFee;
        uint256 royaltyPermille;
        uint256 price = paymentAmt.mul(1000).div((1000 + buyerFeePermille));
        uint256 buyerFee = paymentAmt.sub(price);
        uint256 sellerFee = paymentAmt.mul(sellerFeePermille).div((1000 + buyerFeePermille));
        platformFee = buyerFee.add(sellerFee);

        // If trade with no enigma NFT royalty fee is 0
        if (buyingAssetAddress == enigmaNFT721Address || buyingAssetAddress == enigmaNFT1155Address) {
            royaltyPermille = ((IRoyaltyAwareNFT(buyingAssetAddress).royaltyFee(tokenId)));
            tokenCreator = ((IRoyaltyAwareNFT(buyingAssetAddress).getCreator(tokenId)));
            royaltyFee = paymentAmt.mul(royaltyPermille).div((1000 + buyerFeePermille));
        } else {
            tokenCreator = address(0);
            royaltyFee = 0;
        }
        assetFee = price.sub(royaltyFee).sub(sellerFee);
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function tradeNFT(Order memory order) internal virtual {
        order.nftType == BuyingAssetType.ERC721
            ? transferProxy.erc721safeTransferFrom(order.nftAddress, order.seller, order.buyer, order.tokenId)
            : transferProxy.erc1155safeTransferFrom(
                order.nftAddress,
                order.seller,
                order.buyer,
                order.tokenId,
                order.qty,
                ""
            );
    }

    function tradeAssetWithERC20(Order memory order, Fee memory fee) internal virtual {
        tradeNFT(order);
        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(order.erc20Address, order.buyer, owner, fee.platformFee);
        }
        if (fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(order.erc20Address, order.buyer, fee.tokenCreator, fee.royaltyFee);
        }
        transferProxy.erc20safeTransferFrom(order.erc20Address, order.buyer, order.seller, fee.assetFee);
    }

    /**
     * @dev Disable slither warning because there is a nonReentrant check and the address are known
     * https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
     */
    function tradeAssetWithETH(Order memory order, Fee memory fee) internal virtual {
        tradeNFT(order);
        if (fee.platformFee > 0) {
            // slither-disable-next-line arbitrary-send
            (bool success, ) = owner.call{ value: fee.platformFee }("");
            require(success, "sending ETH to owner failed");
        }
        if (fee.royaltyFee > 0) {
            // slither-disable-next-line arbitrary-send
            (bool success, ) = fee.tokenCreator.call{ value: fee.royaltyFee }("");
            require(success, "sending ETH to creator failed");
        }
        // slither-disable-next-line arbitrary-send
        (bool success, ) = order.seller.call{ value: fee.assetFee }("");
        require(success, "sending ETH to seller failed");
    }

    function buyAsset(Order memory order, Sign memory sign) public returns (bool) {
        Fee memory fee = getFees(order.amount, order.nftAddress, order.tokenId);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifySellerSignature(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        tradeAssetWithERC20(order, fee);
        return true;
    }

    function buyAssetWithETH(Order memory order, Sign memory sign) public payable nonReentrant returns (bool) {
        require(order.amount == msg.value, "Paid invalid ETH amount");
        Fee memory fee = getFees(order.amount, order.nftAddress, order.tokenId);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifySellerSignature(order.seller, order.tokenId, order.unitPrice, address(0), order.nftAddress, sign);
        order.buyer = msg.sender;
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        tradeAssetWithETH(order, fee);
        return true;
    }

    function executeBid(Order memory order, Sign memory sign) public returns (bool) {
        Fee memory fee = getFees(order.amount, order.nftAddress, order.tokenId);
        verifyBuyerSignature(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        order.seller = msg.sender;
        emit ExecuteBid(msg.sender, order.tokenId, order.qty, order.buyer);
        tradeAssetWithERC20(order, fee);
        return true;
    }
}
