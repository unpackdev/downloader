// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EnglishAuctionStorage.sol";
import "./SafeEthSender.sol";
import "./INFT.sol";

contract FinalizeAuctionControllerMint is EnglishAuctionStorage, SafeEthSender {
    event AuctionRoyaltiesPaid(
        uint32 auctionId,
        uint32 nftId,
        address artistAddress,
        uint256 royaltyAmount
    );

    function finalize(uint32 _auctionId) external {
        AuctionStruct storage auction = auctionIdToAuction[_auctionId];

        INFT nft = INFT(auction.nftContractAddress);

        uint32 nftId = nft.nftId();

        if (
            auction.auctionBalance == 0 && auction.bidder == payable(address(0))
        ) {
            emit AuctionRoyaltiesPaid(_auctionId, nftId, address(0), 0);
        } else {
            (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(
                auction.tokenId,
                auction.auctionBalance
            );

            uint256 amountForWithdrawalAddress = auction.auctionBalance -
                royaltyAmount;

            auction.auctionBalance = 0;

            sendEthWithLimitedGas(payable(receiver), royaltyAmount, 5000);

            sendEthWithLimitedGas(
                withdrawalAddress,
                amountForWithdrawalAddress,
                5000
            );

            nft.awardToken(auction.bidder, auction.tokenId);

            emit AuctionRoyaltiesPaid(
                _auctionId,
                nftId,
                receiver,
                royaltyAmount
            );
        }
    }

    function cancel(uint32 _auctionId) external {
        revert();
    }

    function adminCancel(uint32 _auctionId, string memory _reason) external {
        require(
            bytes(_reason).length > 0,
            "English Auction: Include a reason for this cancellation"
        );
        AuctionStruct storage auction = auctionIdToAuction[_auctionId];
        require(auction.timeEnd > 0, "English Auction: Auction not found");
    }

    function getAuctionType() external view returns (string memory) {
        return "MINT";
    }
}
