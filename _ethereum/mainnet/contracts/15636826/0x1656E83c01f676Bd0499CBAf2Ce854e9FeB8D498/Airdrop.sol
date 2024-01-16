// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Holder.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Airdrop is ERC721Holder {
    address public immutable donation;

    constructor() {
        donation = msg.sender;
    }

    function airdrop(
        address nft,
        address[] memory recipients,
        uint256[] memory tokenIds
    ) external {
        IERC721 target = IERC721(nft);
        for (uint256 i = 0; i < recipients.length; i++) {
            target.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}
