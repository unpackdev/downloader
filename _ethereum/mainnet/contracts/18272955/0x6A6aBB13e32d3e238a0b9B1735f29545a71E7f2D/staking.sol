// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";

contract Staking is Ownable {

    mapping(address => uint256) private stakedAmount;
    mapping(address => uint256) private stakedTimestamp;
    uint256 public totalTokenStaked;
    uint256 public totalRewardsDistributed;
    uint256 public totalRewardPending;
    IERC20 private tokenContract;

    constructor() {
        tokenContract = IERC20(0xEB803A6d4F2b208DdEb3A5557b7509d71b2395c1);
    }

    function stake(uint256 _amount) public {
        require(tokenContract.balanceOf(msg.sender) >= _amount, "Stake: INSUFFICIENT AMOUNT");
        require(tokenContract.allowance(msg.sender, address(this)) >= _amount, "Stake: APPROVE BEFORE STAKE");

        stakedAmount[msg.sender] = _amount; 
        stakedTimestamp[msg.sender] = block.timestamp;
 
        tokenContract.transferFrom(msg.sender, address(this), _amount);
    }

    function unstake() public {
        require(stakedAmount[msg.sender] != 0, "Stake: INSUFFICIENT AMOUNT");

        tokenContract.transfer(msg.sender, calculate(msg.sender));
        stakedAmount[msg.sender] = 0; 
    }  

    function calculate(address _address) public view returns (uint256) {
        return stakedAmount[_address] * 1e8 * (100 * 1e8 + (block.timestamp - stakedTimestamp[_address]) * 1e2) / 1e18; 
    }

    function withdrawStuckTokens(uint256 _amount) external onlyOwner {
        tokenContract.transfer(msg.sender, _amount);
    }
}