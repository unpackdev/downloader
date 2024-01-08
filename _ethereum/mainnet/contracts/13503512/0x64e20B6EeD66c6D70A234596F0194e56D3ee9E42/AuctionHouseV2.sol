pragma solidity ^0.8.0;

import "./AuctionHouse.sol";
import "./ISquidDAONFT.sol";

contract AuctionHouseV2 is AuctionHouse {
    function reMintAndSetNewNFT(ISquidDAONFT newSquidDAONFT)
        external
        onlyOwner
    {
        for (uint256 i = 0; i <= auction.squidDAONFTId; i++) {
            // Get owner by token ID.
            address owner = IERC721(address(squidDAONFT)).ownerOf(i);

            // Mint with new NFT.
            newSquidDAONFT.mint(owner);
            squidDAONFT.burn(i);
        }

        // Replace the NFT address.
        squidDAONFT = newSquidDAONFT;
    }
}
