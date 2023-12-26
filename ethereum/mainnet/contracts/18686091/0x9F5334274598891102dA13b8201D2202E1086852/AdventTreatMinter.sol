// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ForgottenRunesTreats.sol";

// I wear the chain I forged in life. I made it link by link, and yard by yard;
// I girded it on of my own free will, and of my own free will I wore it.
contract AdventTreatMinter is Ownable, Pausable {
    ForgottenRunesTreats public treats;
    uint256 public startingTokenId;

    uint256 public constant START_TIMESTAMP = 1701388800; //  1st December 00:00

    uint256 public constant DURATION = 25 days;

    constructor(address treatsAddress, uint256 _startingTokenId) {
        treats = ForgottenRunesTreats(treatsAddress);
        startingTokenId = _startingTokenId;
    }

    function mint(uint256[] calldata tokenIds, uint256[] calldata tokenQuantities) external whenNotPaused {
        require(block.timestamp >= START_TIMESTAMP, "Minting event has not started yet");
        require(block.timestamp <= START_TIMESTAMP + DURATION, "Minting event has ended");

        require(tokenIds.length == tokenQuantities.length, "Must have same number of tokenIds and tokenQuantities");

        uint256 quantitySum;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = tokenQuantities[i];

            // Native burn not supported to send to dEaD address instead
            treats.safeTransferFrom(
                msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenId, quantity, ""
            );

            quantitySum += quantity;
        }

        require(quantitySum >= 2 && quantitySum % 2 == 0, "Must sacrifice treats as multiple of 2");

        treats.mint(msg.sender, startingTokenId + ((block.timestamp - START_TIMESTAMP) / 1 days), quantitySum / 2, "");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
