//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
// import "./Ownable.sol";
import "./LinearDutchAuction.sol";
import "./Pausable.sol";
import "./IMMNFT.sol";

contract MMDutchAuction is LinearDutchAuction
{
    IMMNFT nft;
    constructor(
        address payable beneficiary
    )
        // LinearDutchAuction(
        //     LinearDutchAuction.DutchAuctionConfig({
        //         startPoint: 0, // disabled at deployment
        //         startPrice: 1.5 ether,
        //         unit: AuctionIntervalUnit.Time,
        //         decreaseInterval: 360,
        //         decreaseSize: 0.01 ether,
        //         numDecreases: 135
        //     }),
        //     0.15 ether,
        //     Seller.SellerConfig({
        //         totalInventory: 6080,
        //         lockTotalInventory: true,
        //         maxPerAddress: 12,
        //         maxPerTx: 12,
        //         freeQuota: 0,
        //         lockFreeQuota: true,
        //         reserveFreeQuota: true
        //     }),
        //     beneficiary
        // )
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 0, // disabled at deployment
                startPrice: 0.1 ether,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: 180,
                decreaseSize: 0.01 ether,
                numDecreases: 9
            }),
            0.01 ether,
            Seller.SellerConfig({
                totalInventory: 6080,
                lockTotalInventory: true,
                maxPerAddress: 12,
                maxPerTx: 12,
                freeQuota: 0,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {}

    /// LinearDutchAuction Required Functions
    /// @notice Entry point for purchase of a single token.
    function buy(uint256 count) external payable whenNotPaused {
        Seller._purchase(msg.sender, count);
    }

    /// @notice Internal override of Seller function for handling purchase (i.e. minting).
    function _handlePurchase(
        address to,
        uint256 num,
        bool
    ) internal override {
        nft.adminMint(num, to);
    }

    function setNFT(IMMNFT _nft) external onlyOwner {
        nft = _nft;
    }
}
