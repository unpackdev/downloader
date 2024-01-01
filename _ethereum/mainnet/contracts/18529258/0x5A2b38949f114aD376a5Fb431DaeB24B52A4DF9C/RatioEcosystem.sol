/**
 *Submitted for verification at Etherscan.io on 2023-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RatioEcosystem {
    address public owner;
    mapping(address => bool) public hasClaimed;
    bool public isClaimActive = true;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier claimIsActive() {
        require(isClaimActive, "Claiming is currently paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function claim(uint8 v, bytes32 r, bytes32 s) external claimIsActive {
        require(!hasClaimed[msg.sender], "Already claimed");

        bytes32 message = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));

        address signer = ecrecover(ethSignedMessage, v, r, s);
        require(signer == owner, "Invalid signature");

        hasClaimed[msg.sender] = true;
    }

    function toggleClaim() external onlyOwner {
        isClaimActive = !isClaimActive;
    }


    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }

    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}