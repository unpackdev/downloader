// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC20Interface.sol";

contract ImpactPayments is Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) public deposits; // total deposited funds for a user
    mapping(uint256 => uint256) public campaignDeposits; // total deposited funds for a user
    mapping(address => bool) public allowedTokens;

    event Deposit(address indexed sender, uint256 amount, uint256 campaignId);
    event Withdraw(address indexed recipient, uint256 amount, uint256 campaignId);
    
    constructor(address[] memory tokenList) {
        for(uint256 i = 0; i < tokenList.length; i++) {
            allowedTokens[tokenList[i]] = true;
        }
    }
    
    function withdrawFundsETH(uint256 campaignId, address campaignOwner, uint256 amount) public onlyOwner {
        require(campaignDeposits[campaignId] >= amount, 
                "This campaign does not have sufficient funds for this withdrawal");
        require(address(this).balance >= amount, 
                "This campaign does not have sufficient ETH for this withdrawal");
        payable(campaignOwner).transfer(amount);
        emit Withdraw(campaignOwner, amount, campaignId);
    }

    function depositFundsETH(uint256 campaignId) public payable {
        deposits[msg.sender] += msg.value;
        campaignDeposits[campaignId] += msg.value;
        emit Deposit(msg.sender, msg.value, campaignId);
    }

    function depositFunds(uint256 campaignId, address tokenAddress, uint256 amount) public {
        require(allowedTokens[tokenAddress], "We do not accept this donations of this token type");
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        campaignDeposits[campaignId] += amount;
        emit Deposit(msg.sender, amount, campaignId);
    }

    function createExternalDepositEntry(uint256 campaignId, address donor, uint256 amount) public onlyOwner {
        deposits[donor] += amount;
        campaignDeposits[campaignId] += amount;
        emit Deposit(donor, amount, campaignId);
    }

    function addAllowedToken(address tokenAddress) public onlyOwner {
        allowedTokens[tokenAddress] = true;
    }
}