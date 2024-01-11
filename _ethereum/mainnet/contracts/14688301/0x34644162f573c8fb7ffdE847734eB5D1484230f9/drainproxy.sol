// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";

// is IERC721Receiver 
contract BulkTransfer {
    function bulkTransfer(address to, IERC721Enumerable nft) public {
        uint256 nftBalance = nft.balanceOf(msg.sender);
        require(nftBalance > 0, "No NFTs to transfer.");
        for (uint256 i = 0; i < nftBalance; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, 0);
            nft.transferFrom(msg.sender, to, tokenId);
        }
    }
}