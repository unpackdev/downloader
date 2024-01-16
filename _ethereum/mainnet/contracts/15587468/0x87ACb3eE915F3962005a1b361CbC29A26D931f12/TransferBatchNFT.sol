// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract TransferBatchNFT {
    constructor() {}

    /// @notice transfer a batch of nfts with unconsecutive tokenIDs.
    function transferBatchNFTsByTokenID(
        address nft,
        address receiver,
        uint256[] calldata tokenIDs
    ) public {
        for (uint256 i; i < tokenIDs.length; i++) {
            IERC721(nft).transferFrom(msg.sender, receiver, tokenIDs[i]);
        }
    }

    /// @notice transfer a batch of nfts with consecutive tokenIDs.
    function transferBatchNFTsByAmount(
        address nft,
        address receiver,
        uint256 startTokenID,
        uint256 amount
    ) public {
        for (uint256 i; i < amount; i++) {
            IERC721(nft).transferFrom(msg.sender, receiver, startTokenID + i);
        }
    }
}
