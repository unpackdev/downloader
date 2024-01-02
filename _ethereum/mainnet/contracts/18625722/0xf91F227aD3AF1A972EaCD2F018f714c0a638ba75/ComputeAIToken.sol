/**

Website:  https://www.computeai.tech 

/**
*/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ComputeAIToken {
    string public name = "ComputeAI";
    string public symbol = "COMPUTEAI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10**uint256(decimals);
    address public marketingWallet = 0x8849D9FD0a82F55417D39bFCf5D3473121a74D91;
    address public owner = 0x8849D9FD0a82F55417D39bFCf5D3473121a74D91;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public buyFeePercentage = 2;
    uint256 public sellFeePercentage = 2;
    uint256 public transferFeePercentage = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        balanceOf[owner] = totalSupply;
    }

    function calculateFee(uint256 amount, uint256 feePercentage) internal pure returns (uint256) {
        return (amount * feePercentage) / 100;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fee = calculateFee(value, transferFeePercentage);
        uint256 newValue = value - fee;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += newValue;

        emit Transfer(msg.sender, to, newValue);

        // Collect transfer fee
        if (fee > 0) {
            balanceOf[marketingWallet] += fee;
            emit Transfer(msg.sender, marketingWallet, fee);
        }

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[from] >= value, "ERC20: insufficient balance");
        require(allowance[from][msg.sender] >= value, "ERC20: insufficient allowance");

        uint256 fee = calculateFee(value, transferFeePercentage);
        uint256 newValue = value - fee;

        balanceOf[from] -= value;
        balanceOf[to] += newValue;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, newValue);

        // Collect transfer fee
        if (fee > 0) {
            balanceOf[marketingWallet] += fee;
            emit Transfer(from, marketingWallet, fee);
        }

        return true;
    }

    function setBuyFee(uint256 newFeePercentage) external onlyOwner {
        buyFeePercentage = newFeePercentage;
    }

    function setSellFee(uint256 newFeePercentage) external onlyOwner {
        sellFeePercentage = newFeePercentage;
    }

    function setTransferFee(uint256 newFeePercentage) external onlyOwner {
        transferFeePercentage = newFeePercentage;
    }
}