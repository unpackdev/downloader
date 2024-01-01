// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721.sol";

// ERC-721 functions necessary for our interaction
interface IBlackHole is IERC721 {
    function lastBurner() external view returns (address);
    function withdraw() external;
    function minted() external view returns (uint256);
    function burnt() external view returns (uint256);
    function burn(uint256 tokenId) external;
}

contract HawkingRadiation {
    IBlackHole public blackHoleContract;
    mapping(address => uint256) public burntViaHawking;
    uint256 public collectedEth;
    uint256 public totalBurntViaHawking;

    bool public hasCollected = false;

    constructor(address _blackHoleAddress) {
        blackHoleContract = IBlackHole(_blackHoleAddress);
    }

    function transferAndBurnViaHawking(uint256 tokenId) external {
        require(!hasCollected, "ETH has been collected, cannot burn anymore");

        // Transfer the NFT to this contract
        blackHoleContract.transferFrom(msg.sender, address(this), tokenId);
        
        // Check that this contract is now the owner
        require(blackHoleContract.ownerOf(tokenId) == address(this), "Failed to transfer NFT to HawkingRadiation contract");
        
        // Burn the NFT
        blackHoleContract.burn(tokenId);
        
        burntViaHawking[msg.sender] += 1;
        totalBurntViaHawking += 1;
    }

    function collectBlackHoleETH() external {
        require(!hasCollected, "ETH already collected");

        address lastBurner = blackHoleContract.lastBurner();
        require(lastBurner == address(this), "HawkingRadiation was not the last to burn an NFT");

        uint256 blackHoleBalance = address(blackHoleContract).balance;

        blackHoleContract.withdraw();

        require(address(this).balance == blackHoleBalance, "ETH transfer from Black Hole failed");
        collectedEth = blackHoleBalance;
        hasCollected = true;
    }

    function claimETH() external {
        require(hasCollected, "ETH hasn't been collected yet");
    
        uint256 userBurntCount = burntViaHawking[msg.sender];
        require(userBurntCount > 0, "You haven't burnt any NFT via HawkingRadiation");

        uint256 ethShare = (collectedEth * userBurntCount) / totalBurntViaHawking;

        require(ethShare > 0, "No ETH to claim");

        // Reduce the user's count and the contract's ETH balance
        burntViaHawking[msg.sender] = 0; // Resetting the user's burnt count after claiming
        collectedEth -= ethShare;

        payable(msg.sender).transfer(ethShare);
    }
}
