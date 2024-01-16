// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibERC721.sol";
import "./LibTransfer.sol";
import "./LibFee.sol";
import "./LibMarketplace.sol";
import "./IRentPayout.sol";

contract RentPayout is IRentPayout {
    modifier payout(uint256 tokenId) {
        payoutRent(tokenId);
        _;
    }

    /// @dev Pays out the accumulated rent for a given tokenId
    /// Rent is paid out to consumer if set, otherwise it is paid to the owner of the LandWorks NFT
    function payoutRent(uint256 tokenId) internal returns (address, uint256) {
        address paymentToken = LibMarketplace
            .marketplaceStorage()
            .assets[tokenId]
            .paymentToken;
        uint256 amount = LibFee.clearAccumulatedRent(tokenId, paymentToken);
        if (amount == 0) {
            return (paymentToken, amount);
        }

        address receiver = LibERC721.consumerOf(tokenId);
        if (receiver == address(0)) {
            receiver = LibERC721.ownerOf(tokenId);
        }

        LibTransfer.safeTransfer(paymentToken, receiver, amount);
        emit ClaimRentFee(tokenId, paymentToken, receiver, amount);

        return (paymentToken, amount);
    }
}
