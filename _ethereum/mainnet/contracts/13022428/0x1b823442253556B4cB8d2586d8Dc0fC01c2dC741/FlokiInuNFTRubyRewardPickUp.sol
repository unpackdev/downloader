// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IMintable.sol";
import "./FlokiInuNFTReward.sol";

contract FlokiInuNFTRubyRewardPickUp is Ownable {
    mapping (address => bool) public hasClaimed;
    mapping (address => bool) public hasReward;

    IMintable public immutable rubyNFT;

    constructor(address _rubyNFT) Ownable() {
        rubyNFT = IMintable(_rubyNFT);
    }

    function claimReward() external {
        require(hasReward[msg.sender], "FlokiInuNFTRubyRewardPickUp::INELIGIBLE_ADDRESS");
        require(!hasClaimed[msg.sender], "FlokiInuNFTRubyRewardPickUp::ALREADY_CLAIMED");

        hasClaimed[msg.sender] = true;
        rubyNFT.mint(msg.sender);
    }

    function addBatch(address[] memory batch) external onlyOwner {
        for (uint256 i = 0; i < batch.length; i++) {
            hasReward[batch[i]] = true;
        }
    }
}
