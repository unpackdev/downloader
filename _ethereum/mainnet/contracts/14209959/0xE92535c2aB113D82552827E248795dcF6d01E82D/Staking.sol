// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    IERC20 public stakingToken;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint256 public noOfStakes;
    uint256 public totalStake;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public APR = 150;
    
    mapping(address => uint256) public userStake;
    
    event Staked(address _who, uint256 _when, uint256 _howmuch);
    event UnStaked(address _who, uint256 _when, uint256 _howmuch);

    constructor(address _stakingToken, uint256 _startTime, uint256 _endTime) {
        require(_stakingToken != address(0), "Staking Token can not be Zero Address");
        stakingToken = IERC20(_stakingToken);
        startTime = _startTime;
        endTime = _endTime;
    }
    
    function stake(uint256 amount) external nonReentrant {
        uint256 _time = block.timestamp;
        require(_time >= startTime, "Stake:: To early to Stake");
        require(_time <= endTime, "Stake:: To late to Stake");
        totalStake = totalStake.add(amount);
        userStake[msg.sender] = userStake[msg.sender].add(amount);
        noOfStakes = noOfStakes.add(1);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, _time, amount);
    }

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "Withdraw:: _to Can not be Zero Address");
        uint256 _totalStake = IERC20(stakingToken).balanceOf(address(this));
        stakingToken.safeTransfer(_to, _totalStake);
        emit UnStaked(_to, block.timestamp, _totalStake);
    }
}