// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface NiftySouqIMarketplace {
    enum ContractType {
        NIFTY_V1,
        NIFTY_V2,
        COLLECTOR,
        EXTERNAL,
        UNSUPPORTED
    }

    enum OfferState {
        OPEN,
        CANCELLED,
        ENDED
    }

    enum OfferType {
        SALE,
        AUCTION
    }

    struct Offer {
        uint256 tokenId;
        OfferType offerType;
        OfferState status;
        ContractType contractType;
    }

    struct MintData {
        address minter;
        address tokenAddress;
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
    }

    struct Payout {
        address currency;
        address[] refundAddresses;
        uint256[] refundAmounts;
    }

    function mintNft(MintData memory mintData_)
        external
        returns (
            uint256 tokenId_,
            bool erc1155_,
            address tokenAddress_
        );

    function createSale(uint256 tokenId_, ContractType contractType_, OfferType offerType_)
        external
        returns (uint256 offerId_);

    function endSale(uint256 offerId_, OfferState offerState_) external;

    function payout(Payout memory payoutData_) external;

    function transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) external;

    function getOfferStatus(uint256 offerId_)
        external
        view
        returns (Offer memory offerDetails_);
}
