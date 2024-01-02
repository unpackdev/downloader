// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract NFTLockAndClaimContract is Ownable {
    using SafeMath for uint256;

    struct NFTLock {
        uint256 unlockTimestamp;
        bool isLocked;
    }

    mapping(address => ERC721) public nftContracts;
    mapping(address => mapping(uint256 => NFTLock)) public nftLocks;

    constructor() Ownable(msg.sender){}

    function addNFTContract(address _nftContractAddress) external onlyOwner {
        require(nftContracts[_nftContractAddress] == ERC721(address(0)), "NFT contract already added");
        nftContracts[_nftContractAddress] = ERC721(_nftContractAddress);
    }

    function lockNFT(address nftContractAddress, uint256 tokenId) external {
        require(nftContracts[nftContractAddress].ownerOf(tokenId) == msg.sender, "Not the owner of the NFT");
        require(!nftLocks[nftContractAddress][tokenId].isLocked, "NFT is already locked");

        // Transfer the NFT to the contract
        nftContracts[nftContractAddress].transferFrom(msg.sender, address(this), tokenId);

        // Set the unlock timestamp to one week from now
        uint256 unlockTimestamp = block.timestamp.add(1 weeks);
        nftLocks[nftContractAddress][tokenId] = NFTLock(unlockTimestamp, true);
    }

    function claimNFT(address nftContractAddress, uint256 tokenId) external onlyOwner {
        require(nftLocks[nftContractAddress][tokenId].isLocked, "NFT is not locked");
        require(block.timestamp >= nftLocks[nftContractAddress][tokenId].unlockTimestamp, "NFT is still locked");

        // Transfer the NFT back to the original owner
        nftContracts[nftContractAddress].transferFrom(address(this), msg.sender, tokenId);

        // Reset the lock after claiming
        nftLocks[nftContractAddress][tokenId] = NFTLock(0, false);
    }
}
