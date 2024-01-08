// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IMintable.sol";

contract FlokiInuNFTRewardPickUp is Ownable {
    uint256 private _numRewards;
    mapping (uint256 => IMintable) private _nftContracts;
    mapping (uint256 => mapping (address => bool)) private _hasReward;
    mapping (address => bool) public hasClaimed;

    constructor(address[] memory nftContracts_) Ownable() {
        _numRewards = nftContracts_.length;

        for (uint256 i = 0; i < nftContracts_.length; i++) {
            _nftContracts[i] = IMintable(nftContracts_[i]);
        }
    }

    function hasReward(address user) public view returns (bool) {
        for (uint256 i = 0; i < _numRewards; i++) {
            if (_hasReward[i][user]) {
                return true;
            }
        }

        return false;
    }

    function claimReward() external {
        require(hasReward(msg.sender), "FlokiInuNFTRewardPickUp::INELIGIBLE_ADDRESS");
        require(!hasClaimed[msg.sender], "FlokiInuNFTRewardPickUp::ALREADY_CLAIMED");

        hasClaimed[msg.sender] = true;
        for (uint256 i = 0; i < _numRewards; i++) {
            if (_hasReward[i][msg.sender]) {
                _nftContracts[i].mint(msg.sender);
            }
        }
    }

    function addBatch(uint256 reward, address[] memory batch) external onlyOwner {
        require(reward < _numRewards, "FlokiInuNFTRewardPickUp::INVALID_REWARD");

        for (uint256 i = 0; i < batch.length; i++) {
            _hasReward[reward][batch[i]] = true;
        }
    }
}
