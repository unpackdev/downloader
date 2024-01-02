/*

REMIX Revenue Sharing
Transfer ETH anonymously between your wallets. 🎭

💬 Telegram: https://t.me/remixtoolsgroup
🌐 Website:  https://remix.tools
🕊️ Twitter:  https://twitter.com/remixtools
🤖 Bot:      https://t.me/remixtools_bot
📄 Docs:     https://docs.remix.tools

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract REMIXRevenueSharing is Ownable, ReentrancyGuard {

    bytes32 private merkleRoot;
    mapping(address => uint256) private claimed;

    event ShareClaimed(address from, uint256 totalAmount);
    event ReceivedETH(uint256 amount);

    constructor() {}

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 totalAmount, bytes32[] calldata proof) external nonReentrant {
        require(msg.sender != owner(), "Owner not allowed to claim");
        require(merkleRoot != bytes32(0), "No merkle root set");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid merkle proof");

        require(totalAmount > claimed[msg.sender], "Shares already claimed");
        uint256 claimableAmount = totalAmount - claimed[msg.sender];

        (bool success, ) = address(msg.sender).call{value: claimableAmount}("");
        require(success);

        claimed[msg.sender] += claimableAmount;

        emit ShareClaimed(msg.sender, claimed[msg.sender]);
    }

    function getClaimedAmount(address _address) public view returns (uint256) {
        return claimed[_address];
    }

    receive() external payable {
        emit ReceivedETH(msg.value);
    }
}
