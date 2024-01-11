// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EnglishAuction.sol";
import "./IAccessManager.sol";
import "./INFT.sol";

contract MintAuctionCreator {
    address englishAuctionAddress;
    address finalizeAuctionControllerAddress;
    EnglishAuction englishAuction;
    IAccessManager accessManager;

    constructor(
        address _englishAuctionAddress,
        address _accessManangerAddress,
        address _finalizeAuctionControllerAddress
    ) {
        englishAuctionAddress = _englishAuctionAddress;
        finalizeAuctionControllerAddress = _finalizeAuctionControllerAddress;
        englishAuction = EnglishAuction(englishAuctionAddress);
        accessManager = IAccessManager(_accessManangerAddress);
    }

    modifier isOperationalAddress() {
        require(
            accessManager.isOperationalAddress(msg.sender) == true,
            "Mint Auction Creator: You are not allowed to use this function"
        );
        _;
    }

    function createMintAuction(
        uint8 _minBidPercentage,
        uint256 _initialPrice,
        uint256 _minBidValue,
        address _nftContractAddress
    ) public isOperationalAddress {
        require(
            _initialPrice > 0,
            "Mint Auction Creator: Initial price have to be bigger than zero"
        );

        INFT nft = INFT(_nftContractAddress);

        uint32 editions = nft.totalAmountOfEdition();
        uint32 timeStart = nft.timeStart();
        uint32 timeEnd = nft.timeEnd();

        for (uint32 tokenId = 1; tokenId <= editions; tokenId++) {
            englishAuction.createAuction(
                tokenId,
                timeStart,
                timeEnd,
                _minBidPercentage,
                _initialPrice,
                _minBidValue,
                _nftContractAddress,
                finalizeAuctionControllerAddress,
                "0x"
            );
        }
    }
}
