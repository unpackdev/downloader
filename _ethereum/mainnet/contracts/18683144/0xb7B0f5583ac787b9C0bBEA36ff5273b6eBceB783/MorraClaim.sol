//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract MorraClaim is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token; // Assuming ERC-20 token

    // Mapping to store assigned token balances
    mapping(address => uint256) public assignedBalances;

    // Mapping to store claimed token balances
    mapping(address => uint256) public claimedBalances;

    // Flag to indicate if the airdrop has started
    bool public isStarted = false;
    
    // Timestamp when the airdrop starts
    uint256 public startTime;

    // Duration of the airdrop
    uint256 public constant DURATION = 30 days;

    // Events
    event TokensAssigned(uint256 userCount, uint256 totalAmount);
    event TokenClaimed(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // Function for the owner to start the airdrop
    function startClaim() external onlyOwner {
        require(!isStarted, "Airdrop already started");

        // Set the start time
        startTime = block.timestamp;

        // Set the flag to true
        isStarted = true;
    }

    // Function for the owner to stop the airdrop
    function stopClaim() external onlyOwner {
        require(isStarted, "Airdrop not started");

        // Set the flag to false
        isStarted = false;
    }

    // Function to get the remaining time of the airdrop
    function remainingTime() public view returns (uint256) {
        if (isStarted) {
            uint256 endTime = startTime + DURATION;
            if (block.timestamp < endTime) {
                return endTime - block.timestamp;
            }
        }
        return 0;
    }

    // Function to check if the airdrop is active
    function isActive() public view returns (bool) {
        return isStarted && block.timestamp < startTime + DURATION;
    }

    // Function for the owner to assign tokens to users
    function assignTokens(address[] calldata _users, uint256[] calldata _tokenAmounts) external onlyOwner {
        require(_users.length == _tokenAmounts.length, "Arrays length mismatch");
        
        // calculate the total token amount to be assigned
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _tokenAmounts.length; i++) {
            totalAmount += _tokenAmounts[i];
        }
        require(totalAmount > 0, "Invalid Token amount");
        // Ensure the owner has enough balance
        require(token.balanceOf(owner()) >= totalAmount, "Insufficient balance in owner's wallet");

        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            uint256 tokenAmount = _tokenAmounts[i];

            require(user != address(0), "Invalid user address");
            require(tokenAmount > 0, "Invalid Token amount");

            // Update the assigned balance for the user
            assignedBalances[user] = tokenAmount;
        }

        // Perform the transferFrom to assign tokens
        token.safeTransferFrom(owner(), address(this), totalAmount);

        // Emit the event
        emit TokensAssigned(_users.length, totalAmount);
    }

    // Function for users to claim their assigned tokens
    function claimToken() external {
        require(isActive(), "Airdrop not active");

        uint256 assignedAmount = assignedBalances[msg.sender];
        require(assignedAmount > 0, "No token assigned to claim");

        uint256 claimedAmount = claimedBalances[msg.sender];
        require(assignedAmount > claimedAmount, "No token remained to claim");

        uint256 claimableAmount = assignedAmount - claimedAmount;

        // Update the user's claimed balance
        claimedBalances[msg.sender] = claimedAmount + claimableAmount;

        // Perform the transfer to the user
        token.safeTransfer(msg.sender, claimableAmount);

        // Emit the event
        emit TokenClaimed(msg.sender, claimableAmount);
    }

    // Function for the owner to withdraw unclaimed tokens
    function withdrawToken(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Invalid Token amount");

        uint256 totalAmount = token.balanceOf(address(this));
        require(totalAmount > 0, "No token assigned to withdraw");

        uint256 withdrawableAmount = tokenAmount > totalAmount ? totalAmount : tokenAmount;

        // Perform the transfer to the owner
        token.safeTransfer(owner(), withdrawableAmount);
    }
}