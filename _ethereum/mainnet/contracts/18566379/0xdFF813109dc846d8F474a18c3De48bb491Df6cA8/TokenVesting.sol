/*         _   _______ ______ _____  
     /\   | | |__   __|  ____|_   _| 
    /  \  | |    | |  | |__    | |   
   / /\ \ | |    | |  |  __|   | |   
  / ____ \| |____| |  | |     _| |_  
 /_/    \_\______|_|  |_|    |_____|                                                                     
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenVesting {
    address public owner;
    IERC20 public vestedToken;
    uint256 public start;
    uint256 public duration;
    uint256 public totalVestedAmount;
    uint256 public amountClaimed;

    event VestedTokenSet(address indexed tokenAddress);
    event TokensVested(uint256 amount);
    event TokensClaimed(address claimant, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        duration = 6 * 30 days; // 6 months vesting period
    }

    function setVestedToken(address _tokenAddress) external onlyOwner {
        require(address(vestedToken) == address(0), "Vested token already set");
        vestedToken = IERC20(_tokenAddress);
        emit VestedTokenSet(_tokenAddress);
    }

    function beginVesting(uint256 _totalVestedAmount) external onlyOwner {
        require(address(vestedToken) != address(0), "Vested token not set");
        require(start == 0, "Vesting already started");
        require(_totalVestedAmount > 0, "Amount must be greater than 0");
        require(vestedToken.transferFrom(msg.sender, address(this), _totalVestedAmount), "Transfer failed");
        
        start = block.timestamp;
        totalVestedAmount = _totalVestedAmount;
        emit TokensVested(_totalVestedAmount);
    }

    function claim() external {
        require(start > 0, "Vesting not started");
        require(block.timestamp >= start, "Vesting period has not started yet");
        uint256 vestedAmount = (totalVestedAmount * (block.timestamp - start)) / duration;
        uint256 claimableAmount = vestedAmount - amountClaimed;
        require(claimableAmount > 0, "No claimable amount available");
        amountClaimed += claimableAmount;
        vestedToken.transfer(msg.sender, claimableAmount);
        emit TokensClaimed(msg.sender, claimableAmount);
    }
}