// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./EIP712.sol";

error WrongBuyerSignature();
error WrongPlatformSignature();
error WrongSellerSignature();
error PlatformSignatureExpired();

abstract contract Protected is Ownable, EIP712 {
    using ECDSA for bytes32;

    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant _ORDER_TYPEHASH =
        keccak256(
            "OrderInfo(address signer,address tokenAddress,uint256 tokenId,uint256 totalTrading,address currency,uint96 feeRate,uint256 price,bool isInitial)"
        );
    bytes32 private constant _MINT_TYPEHASH =
        keccak256(
            "MintInfo(uint256 totalSupply,string meta,address royaltyReceiver,uint96 royalty)"
        );
    bytes32 internal constant _SALE_TYPEHASH =
        // prettier-ignore
        keccak256(
            "SaleParams(address seller,uint256 listingId,OrderInfo order,uint256 startTime,uint256 endTime,MintInfo mint)"
            "MintInfo(uint256 totalSupply,string meta,address royaltyReceiver,uint96 royalty)"
            "OrderInfo(address signer,address tokenAddress,uint256 tokenId,uint256 totalTrading,address currency,uint96 feeRate,uint256 price,bool isInitial)"
        );
    bytes32 internal constant _OFFER_TYPEHASH =
        // prettier-ignore
        keccak256(
            "OfferParams(address buyer,uint256 offerId,OrderInfo order,uint256 endTime,MintInfo mint)"
            "MintInfo(uint256 totalSupply,string meta,address royaltyReceiver,uint96 royalty)"
            "OrderInfo(address signer,address tokenAddress,uint256 tokenId,uint256 totalTrading,address currency,uint96 feeRate,uint256 price,bool isInitial)"
        );

    bytes32 internal constant _PLATFORM_TYPEHASH =
        keccak256(
            "PlatformParams(address receiver,uint256 editionsToBuy,bytes sellerSignature,uint256 expirationTime)"
        );
    bytes32 internal constant _PLATFORM_OFFER_TYPEHASH =
        keccak256(
            "PlatformOfferParams(address seller,uint256 editionsToSell,bytes buyerSignature,uint256 expirationTime)"
        );

    bytes32 internal constant _BID_TYPEHASH =
        keccak256(
            "PlatformBidParams(uint256 listingId,address currency,uint256 price,uint256 expirationTime)"
        );

    struct OrderInfo {
        address signer;
        address tokenAddress;
        uint256 tokenId;
        uint256 totalTrading;
        address currency;
        uint96 feeRate;
        uint256 price;
        bool isInitial;
    }

    struct MintInfo {
        uint256 totalSupply;
        string meta;
        address royaltyReceiver;
        uint96 royalty;
    }

    struct SaleParams {
        address payable seller;
        uint256 listingId;
        OrderInfo order;
        uint256 startTime;
        uint256 endTime;
        MintInfo mint;
    }
    struct OfferParams {
        address buyer;
        uint256 offerId;
        OrderInfo order;
        uint256 endTime;
        MintInfo mint;
    }
    struct PlatformParams {
        address receiver;
        uint256 editionsToBuy;
        bytes sellerSignature;
        uint256 expirationTime;
    }
    struct PlatformOfferParams {
        address payable seller;
        uint256 editionsToSell;
        bytes buyerSignature;
        uint256 expirationTime;
    }
    struct PlatformBidParams {
        uint256 listingId;
        address currency;
        uint256 price;
        uint256 expirationTime;
    }
    address public platform;

    constructor() EIP712("NFTMarketplace", "1.0") {}

    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual override returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorOverriden(), structHash);
    }

    function _domainSeparatorOverriden() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DOMAIN_TYPEHASH,
                    keccak256(bytes("NFTMarketplace")),
                    keccak256(bytes("1.0")),
                    block.chainid,
                    address(0)
                )
            );
    }

    /// @notice Set the platform address
    /// @param _platform New address of the platform
    function setPlatform(address _platform) external onlyOwner {
        platform = _platform;
    }

    /// @notice Check the signature for signed direct sale & auction
    /// @param saleData Sale params
    /// @param sellerSig Signature of seller
    /// @return True, if signature signer matches the seller
    function _checkSaleSignature(
        SaleParams calldata saleData,
        bytes calldata sellerSig
    ) internal view returns (bool) {
        bytes32 hashStruct = _getSaleHashStruct(saleData);
        address signer = _hashTypedDataV4(hashStruct).recover(sellerSig);

        return signer == saleData.order.signer;
    }

    /// @notice Check the signature for signed offers
    /// @param offerData Offer params
    /// @param buyerSig Signature of buyer
    /// @return True, if signature signer matches the seller
    function _checkOfferSignature(
        OfferParams calldata offerData,
        bytes calldata buyerSig
    ) internal view returns (bool) {
        bytes32 hashStruct = _getOfferHashStruct(offerData);
        address signer = _hashTypedDataV4(hashStruct).recover(buyerSig);

        return signer == offerData.order.signer;
    }

    /// @notice Сheck the signature of the platform (Direct Sale & Auction)
    /// @param platformData Buyer address & seller signature
    /// @param platformSig Platform signature
    /// @return True, if signature signer matches the platform
    function _checkPlatformSignature(
        PlatformParams calldata platformData,
        bytes calldata platformSig
    ) internal view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _PLATFORM_TYPEHASH,
                    platformData.receiver,
                    platformData.editionsToBuy,
                    keccak256(platformData.sellerSignature),
                    platformData.expirationTime
                )
            )
        ).recover(platformSig);

        return signer == platform;
    }

    /// @notice Сheck the signature of the platform (Offers)
    /// @param platformData Seller address & buyer signature
    /// @param platformSig Platform signature
    /// @return True, if signature signer matches the platform
    function _checkPlatformOfferSignature(
        PlatformOfferParams calldata platformData,
        bytes calldata platformSig
    ) internal view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _PLATFORM_OFFER_TYPEHASH,
                    platformData.seller,
                    platformData.editionsToSell,
                    keccak256(platformData.buyerSignature),
                    platformData.expirationTime
                )
            )
        ).recover(platformSig);

        return signer == platform;
    }

    /// @notice Сheck the signature of the platform (Bids)
    /// @param bidData Listing id, address of currency to pay, amount to pay
    /// @param bidSignature Platform signature
    /// @return True, if signature signer matches the platform
    function _checkPlatformBidSignature(
        PlatformBidParams calldata bidData,
        bytes calldata bidSignature
    ) internal view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _BID_TYPEHASH,
                    bidData.listingId,
                    bidData.currency,
                    bidData.price,
                    bidData.expirationTime
                )
            )
        ).recover(bidSignature);
        return signer == platform;
    }

    function _getOrderHashStruct(
        OrderInfo calldata order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    order.signer,
                    order.tokenAddress,
                    order.tokenId,
                    order.totalTrading,
                    order.currency,
                    order.feeRate,
                    order.price,
                    order.isInitial
                )
            );
    }

    function _getMintHashStruct(
        MintInfo calldata mint
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _MINT_TYPEHASH,
                    mint.totalSupply,
                    keccak256(bytes(mint.meta)),
                    mint.royaltyReceiver,
                    mint.royalty
                )
            );
    }

    /// @notice Calculate hash struct for Direct Sale & Auction
    function _getSaleHashStruct(
        SaleParams calldata saleData
    ) internal pure returns (bytes32) {
        bytes32 orderHashStruct = _getOrderHashStruct(saleData.order);
        bytes32 mintHashStruct = _getMintHashStruct(saleData.mint);
        return
            keccak256(
                abi.encode(
                    _SALE_TYPEHASH,
                    saleData.seller,
                    saleData.listingId,
                    orderHashStruct,
                    saleData.startTime,
                    saleData.endTime,
                    mintHashStruct
                )
            );
    }

    /// @notice Calculate hash struct for offer
    function _getOfferHashStruct(
        OfferParams calldata offerData
    ) internal pure returns (bytes32) {
        bytes32 orderHashStruct = _getOrderHashStruct(offerData.order);
        bytes32 mintHashStruct = _getMintHashStruct(offerData.mint);
        return
            keccak256(
                abi.encode(
                    _OFFER_TYPEHASH,
                    offerData.buyer,
                    offerData.offerId,
                    orderHashStruct,
                    offerData.endTime,
                    mintHashStruct
                )
            );
    }
}
