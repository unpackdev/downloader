// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

contract LPDistributionContract {
    address public owner;
    mapping(address => uint256) private claimTimestamps;
    uint256 public claimDuration = 5 hours;
    uint256 private minEthContract;
    uint256 public minLPTokenHolding;
    uint256 public minEthWithdraw;  
    address public lpTokenAddress;
    IUniswapV2Pair public lpToken;

    constructor(address _lpTokenAddress) {
        owner = msg.sender;
        lpTokenAddress = _lpTokenAddress;
        lpToken = IUniswapV2Pair(_lpTokenAddress);
        minEthContract = 100000000000000000;
        minLPTokenHolding = 1;
        minEthWithdraw = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setLPTokenAddress(address _newLPTokenAddress) external onlyOwner {
        lpTokenAddress = _newLPTokenAddress;
        lpToken = IUniswapV2Pair(_newLPTokenAddress);
    }

    function setMinLPTokenHolding(uint256 _newMinLPTokenHolding) external onlyOwner {
        minLPTokenHolding = _newMinLPTokenHolding;
    }

    function setMinEth(uint256 _newMinEth) external onlyOwner {
        minEthContract = _newMinEth;
    }

    function setMinEthWithdraw(uint256 _newMinEthWithdraw) external onlyOwner {
        minEthWithdraw = _newMinEthWithdraw;
    }

    function setClaimDuration(uint256 _newDuration) external onlyOwner {
        claimDuration = _newDuration;  
    }

    function claim() external {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > minEthContract, "You can't claim yet");
        require(canClaim(msg.sender), "You can't claim yet");

        uint256 userBalance = lpToken.balanceOf(msg.sender);
        require(userBalance > minLPTokenHolding, "You're holding insufficient LP tokens");

        uint256 totalSupply = lpToken.totalSupply();
        uint256 percentage = (userBalance * 10000) / totalSupply;
        uint256 amountToTransfer = (contractBalance * percentage) / 10000;
        
        require(contractBalance >= minEthWithdraw, "Amount is less than the withdrawal limit");        
        require(amountToTransfer <= contractBalance, "Insufficient contract balance");

        claimTimestamps[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amountToTransfer);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

    function canClaim(address user) public view returns (bool) {
        return claimTimestamps[user] + claimDuration <= block.timestamp;
    }

    function withdrawBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        payable(owner).transfer(contractBalance);
    }

    receive() external payable {
        // Accept ETH
    }
}