/**
 *Submitted for verification at Etherscan.io on 2023-10-13
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FameReward {
    address public owner;
    mapping(address => bool) public hasClaimed;
    bool public isClaimActive = true;

    /// @notice Ensures that the caller is the owner of the contract.
    /// @dev Throws an error if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    /// @notice Ensures that the claim functionality is currently active.
    /// @dev Throws an error if the claim functionality is paused.
    modifier claimIsActive() {
        require(isClaimActive, "Claiming is currently paused");
        _;
    }

    /// @notice Initializes the contract and sets the owner to the deployer.
    /// @dev Sets the initial owner of the contract to the address that deploys it.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Allows a user to claim using the owner's signature.
    /// @dev Uses EIP-712 typed data and ecrecover to verify the owner's signature.
    /// Throws an error if the user has already claimed or if the signature is invalid.
    /// @param v Recovery id of the signature.
    /// @param r First output of the ECDSA signature.
    /// @param s Second output of the ECDSA signature.
    function claim(uint8 v, bytes32 r, bytes32 s) external claimIsActive {
        require(!hasClaimed[msg.sender], "Already claimed");

        bytes32 message = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );

        address signer = ecrecover(ethSignedMessage, v, r, s);
        require(signer == owner, "Invalid signature");

        hasClaimed[msg.sender] = true;
        // Logic to transfer tokens or other claimable items goes here
    }

    /// @notice Allows the owner to toggle the claim functionality on or off.
    /// @dev Toggles the state of the `isClaimActive` variable.
    function toggleClaim() external onlyOwner {
        isClaimActive = !isClaimActive;
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens from the contract.
    /// @dev Transfers the full balance of the specified ERC20 token to the owner.
    /// Throws an error if the transfer fails.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }

    /// @notice Allows the owner to withdraw any ETH from the contract.
    /// @dev Transfers the full ETH balance of the contract to the owner.
    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}
