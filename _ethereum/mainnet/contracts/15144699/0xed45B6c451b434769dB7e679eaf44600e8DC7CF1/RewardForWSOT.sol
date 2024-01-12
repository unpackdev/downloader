// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract RewardForWSOT is Ownable {
    event ClaimNFT(address winner, uint256 tokenId);

    address public nft;
    uint256 public index;
    uint256[] public tokenIds;
    mapping(address => bool) public isWinner;
    mapping(address => uint256) public claimedToken;

    constructor(address nft_) {
        nft = nft_;
    }

    function addTokenIds(uint256[] memory tokenIds_) external onlyOwner {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            tokenIds.push(tokenIds_[i]);
        }
    }

    function addWinners(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            isWinner[users[i]] = true;
        }
    }

    function removeWinners(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            isWinner[users[i]] = false;
        }
    }

    function claimNFT() external returns (uint256) {
        require(isWinner[msg.sender], "FORBIDDEN");
        require(index < tokenIds.length, "NO_TOKENS");

        uint256 tokenId;
        while (index < tokenIds.length) {
            tokenId = tokenIds[index];
            if (IERC721(nft).ownerOf(tokenId) == address(this)) {
                IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);
                isWinner[msg.sender] = false;
                index = index +1;
                claimedToken[msg.sender] = tokenId;
                emit ClaimNFT(msg.sender, tokenId);
                return tokenId;
            } else {
                index = index + 1;
            }
        }
        return 0;
    }
}