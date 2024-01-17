// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";

// A simple contract for batch sending NFTs
contract WAGMINFTSender {
    struct Transfer {
        address owner;
        uint256 tokenId;
    }

    function send(IERC721 _nftCollection, Transfer[] calldata transfers) external {
        IERC721 nftCollection = _nftCollection;

        if (!nftCollection.isApprovedForAll(msg.sender, address(this))) {
            nftCollection.setApprovalForAll(address(this), true);
        }

        for (uint256 i = 0; i < transfers.length; i++) {
            nftCollection.transferFrom(msg.sender, transfers[i].owner, transfers[i].tokenId);
        }
    }
}
