// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract Presale is Ownable {

    IERC20 kataToken;

    uint256 public fundingGoal = 25 ether;    //  ETH

    uint256 public soldAmount;
    uint256 public ethRaised;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public whitelistTime;

    uint256 public minETHAmount = 0.025 ether;
    uint256 public maxETHAmount = 0.06 ether;

    uint256 public price = 5333333;       // 1 ETH = 5333333 $KATA

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public buyETH;
    mapping(address => uint256) public buyTokens;
    mapping(address => uint256) public claimedTokens;

    uint256 public tgeAmount = 15;
    uint256 public tgeCliffTime = 1645617600;
    uint256 public tgeTime = 1640260800;
    uint256 public duration = 60 * 60 * 24 * 30 * 5;    // 5 months

    constructor(uint256 _startTime, uint256 _endTime, uint256 _whitelistTime, uint256 _tgeTime, uint256 _tgeCliffTime) {
        startTime = _startTime;
        endTime = _endTime;
        whitelistTime = _whitelistTime;
        tgeTime = _tgeTime;
        tgeCliffTime = _tgeCliffTime;
    }

    function buy() payable external {
        require(msg.value > 0, "Zero ETH sent");
        require(msg.value >= minETHAmount && msg.value <= maxETHAmount,
            "Invalid ETH amount");

        require(block.timestamp >= startTime && block.timestamp <= endTime,
            "Sales not live");

        require(ethRaised < fundingGoal, "sales completed");
        require(buyETH[msg.sender] + msg.value <= maxETHAmount,"max eth amount exceeds");

        if (block.timestamp < whitelistTime) {
            require(whitelist[msg.sender], "you are not whitelisted");
        }

        ethRaised = ethRaised + msg.value;
        uint256 amount = price * msg.value;

        soldAmount = soldAmount + amount;
        buyTokens[msg.sender] = buyTokens[msg.sender] + amount;
        buyETH[msg.sender] = buyETH[msg.sender] + msg.value;
    }

    function getClaimable() public view returns(uint256) {
        if (block.timestamp < tgeTime) return 0;
        if (block.timestamp < tgeCliffTime) {
          return (buyTokens[msg.sender] * tgeAmount) / 100;
        }
        if (buyTokens[msg.sender] <= 0) return 0;
        if (buyTokens[msg.sender] <= claimedTokens[msg.sender]) return 0;

        uint256 timeElapsed = block.timestamp - tgeCliffTime;

        if (timeElapsed > duration)
            timeElapsed = duration;

        uint256 _tge = 100 - tgeAmount;
        uint256 unlockedPercent = (10**6 * _tge * timeElapsed) / duration;
        unlockedPercent = unlockedPercent + tgeAmount * 10**6;

        uint256 unlockedAmount = (buyTokens[msg.sender] * unlockedPercent) / (100 * 10**6);

        if (unlockedAmount < claimedTokens[msg.sender]) {
          return 0;
        }

        uint256 claimable = unlockedAmount - claimedTokens[msg.sender];

        return claimable;
    }

    function claim() external {
        require(block.timestamp > endTime, "Sales not ended yet");
        require(buyTokens[msg.sender] > 0, "No token purcahsed");
        require(buyTokens[msg.sender] > claimedTokens[msg.sender], "You already claimed all");
        require(address(kataToken) != address(0), "Not initialised");

        uint256 claimable = getClaimable();

        require (claimable > 0, "No token to claim");

        kataToken.transfer(msg.sender, claimable);

        claimedTokens[msg.sender] = claimedTokens[msg.sender] + claimable;
    }

    function withdrawETH() external onlyOwner {
        uint256 ethAmount = address(this).balance;
        payable(msg.sender).transfer(ethAmount);
    }

    function setSalesTime(uint256 _startTime, uint256 _endTime, uint256 _whitelistTime) external onlyOwner {
        require(_whitelistTime < _endTime, "Invalid time");
        require(_startTime < _whitelistTime, "Invalid time");

        startTime = _startTime;
        endTime = _endTime;
        whitelistTime = _whitelistTime;
    }

    function setETHrange(uint256 _minETHAmount, uint256 _maxETHAmount) external onlyOwner {
        require(minETHAmount < maxETHAmount, "Invalid range");
        minETHAmount = _minETHAmount;
        maxETHAmount = _maxETHAmount;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setVesting(uint256 _tgeAmount, uint256 _tgeTime, uint256 _tgeCliffTime, uint256 _duration) external onlyOwner {
        tgeAmount = _tgeAmount;
        tgeTime = _tgeTime;
        tgeCliffTime = _tgeCliffTime;
        duration = _duration;
    }

    function setKataToken(address _kata) external onlyOwner {
        kataToken = IERC20(_kata);
    }

    function setFundingGoal(uint256 _fundingGoal) external onlyOwner {
        fundingGoal = _fundingGoal;
    }

    function registerWhitelist(address[] memory addrs) external onlyOwner {
        for(uint256 i = 0; i < addrs.length; i++)
            whitelist[addrs[i]] = true;
    }
}
