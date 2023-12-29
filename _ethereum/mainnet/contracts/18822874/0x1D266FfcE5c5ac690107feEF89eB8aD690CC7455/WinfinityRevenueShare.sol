/*

WINFINITY + REVENUE SHARING

Revenue shareing is comprised of 20% from lottery ticket sales 
and 33% from collected trading fees.

Website:  https://winfinity.bet
Telegram: https://t.me/winfinitybet
Twitter:  https://twitter.com/winfinitybet
Bot:      https://t.me/winfinitybet_bot
dApp:     https://app.winfinity.bet
Docs:     https://docs.winfinity.bet

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract WinfinityRevenueSharing is Ownable, ReentrancyGuard {

    bytes32 private merkleRoot;
    mapping(address => uint256) public claimed;

    event Claimed(address from, uint256 totalAmount);
    event ReceivedETH(uint256 amount);

    constructor() {}

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 totalAmount, bytes32[] calldata proof) external nonReentrant {
        require(merkleRoot != bytes32(0), "Merkle root not set");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid merkle proof");

        require(totalAmount > claimed[msg.sender], "Already claimed");
        uint256 claimableAmount = totalAmount - claimed[msg.sender];

        (bool success, ) = address(msg.sender).call{value: claimableAmount}("");
        require(success);

        claimed[msg.sender] += claimableAmount;

        emit Claimed(msg.sender, claimed[msg.sender]);
    }

    receive() external payable {
        emit ReceivedETH(msg.value);
    }
}
