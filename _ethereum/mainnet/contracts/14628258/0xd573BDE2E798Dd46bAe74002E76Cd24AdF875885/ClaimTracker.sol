//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract ClaimTracker {
    mapping(uint256 => bool) public unclaimed;
    IERC721 public nft;

    constructor(IERC721 nft_, uint256[] memory tokenIds_) {
        nft = nft_;
        for(uint256 i = 0; i<tokenIds_.length; i++){
            unclaimed[tokenIds_[i]] = true;
        }
    }

    function claim(uint256 tokenId_) public {
        require(msg.sender == nft.ownerOf(tokenId_), "Not owner of declared nft");
        require(unclaimed[tokenId_], "tokenId is unclaimable");
        unclaimed[tokenId_] = false;
    }
}
