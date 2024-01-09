// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";

interface INFTPotion is IERC721 {
    /**
        Contains the info about a range of NFTs purchased by the user

        @param startTokenId The first token ID of the range
        @param amount The amount of tokens in the range
     */
    struct PurchasedRange {
        uint32 startTokenId;
        uint32 amount;
    }

    function getSecretPositionLength(uint256 tokenId)
        external
        returns (
            uint256 start,
            uint256 length,
            bool found
        );
}
