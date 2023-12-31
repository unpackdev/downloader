// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

contract EthTreasury{
    address public owner;
    uint256 public withdrawTimes = 0;
    uint256 public lastWithdrawTimestamp = 0;
    uint256 public constant WITHDRAW_MAX_TIMES = 360;
    uint256 public constant WITHDRAW_ONE_MONTH = 2592000;                 // 1 month(60*60*24*30 seconds)
    uint256 public constant WITHDRAW_START_TIMESTAMP = 1893456000;        // 2030-01-01

    constructor() payable {
        owner = msg.sender;  
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only the owner can call this function");
        _;
    }

    receive() external payable {}

    function getBlockInfo() public view returns(uint256 block_number,uint256 block_timestamp) {
        return (block.number,block.timestamp);
    }

    event EthWithdraw(uint256 withdrawTimes,uint256 withdrawAmount,uint256 timestamp);

    function WithDrawMonthly() external onlyOwner {
        require(block.timestamp >= WITHDRAW_START_TIMESTAMP,"Withdrawal time not reached");
        require(block.timestamp - lastWithdrawTimestamp >= WITHDRAW_ONE_MONTH,"Can only withdraw once per month");

        uint256 amountToSend = address(this).balance / (WITHDRAW_MAX_TIMES - withdrawTimes);  

        (bool success, ) = owner.call{value: amountToSend}("");
        require(success, "ETH transfer failed");  

        emit EthWithdraw(withdrawTimes,amountToSend,block.timestamp);

        withdrawTimes++;   
        lastWithdrawTimestamp = block.timestamp; 
    }

    function WithdrawalAllEmergencybyTimestamp() external onlyOwner {
        require((block.timestamp == 0) || (block.timestamp == 2**256-1),"Block timestamp still works");

        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");   
    }    

    function WithdrawalAllEmergencybyBlocknum() external onlyOwner {
        require(block.number >= 500000000,"Block number not reached");

        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");   
    }           
} 