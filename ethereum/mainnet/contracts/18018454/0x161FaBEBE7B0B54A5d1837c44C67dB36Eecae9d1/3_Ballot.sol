// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IERC20.sol";

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract Staking is ReentrancyGuard {
    address public owner;
    address public dead = 0x000000000000000000000000000000000000dEaD;

    IERC20 public token;
    IERC20 public rewardsToken;

    uint256 public rewardsPerSecond;
    uint256 public rewardsDenominator;
    uint256 public totalStaked;
    uint256 public totalRewardsDistributed;

    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userStakedTimestamp;
    mapping(address => uint256) public userCollectedRewards;
    mapping(address => uint256) public userCurrentRewards;

    modifier moreThanZero(uint256 amount) {
        require(amount > 0, 'Amount should be greater than zero!');
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, 'Only owner can use this function.');
        _;
    }

    constructor(address stakingToken, address rewardToken, uint _rewardsPerSecond, uint _rewardsDenominator) {
        owner = msg.sender;
        token = IERC20(stakingToken);
        rewardsToken = IERC20(rewardToken);
        rewardsPerSecond = _rewardsPerSecond;
        rewardsDenominator = _rewardsDenominator;
    }

    function stake(uint256 amount) external moreThanZero(amount) nonReentrant {
        if(userStakedTimestamp[msg.sender] == 0) userStakedTimestamp[msg.sender] = block.timestamp;
        calculateRewards(msg.sender);

        userStaked[msg.sender] += (amount * 95) / 100;
        totalStaked += (amount * 95) / 100;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdrawAll() external nonReentrant {
        require(userStaked[msg.sender] > 0, "You don't have any tokens to withdraw!");
        uint userLastStakeTime = userStakedTimestamp[msg.sender];
        calculateRewards(msg.sender);
        if(userCurrentRewards[msg.sender] > 0) distributeRewards(msg.sender);
        uint amount = userStaked[msg.sender];
        userStaked[msg.sender] = 0;
        totalStaked -= amount;
        //if user withdraws before 15 days of staking, penalize for 20% and burn the penalty fee, otherwise send the full amount
        if(block.timestamp < userLastStakeTime + 15 days){
            token.transfer(msg.sender, amount * 80 / 100);
            token.transfer(dead, amount * 20 / 100);
        }else token.transfer(msg.sender, amount);
    }

    function calculateRewards(address userAddress) internal returns(uint){
        if(userStaked[userAddress] == 0){
            userCurrentRewards[userAddress] = 0;
        }else{
            userCurrentRewards[userAddress] += (userStaked[userAddress] * rewardsPerSecond * (block.timestamp - userStakedTimestamp[userAddress])) / rewardsDenominator;
        }
        userStakedTimestamp[userAddress] = block.timestamp;
        return userCurrentRewards[userAddress];
    }

    function claimRewards() public nonReentrant {
        distributeRewards(msg.sender);
    }

    function distributeRewards(address userAddress) private {
        uint userRewards = calculateRewards(userAddress);
        require(userRewards > 0, 'You have no rewards to claim!');
        userStakedTimestamp[userAddress] = block.timestamp;
        userCollectedRewards[userAddress] += userRewards;
        totalRewardsDistributed += userRewards;
        userCurrentRewards[userAddress] = 0;
        rewardsToken.transfer(userAddress, userRewards);
    }

    function viewRewards() public view returns (uint){
        if(userStaked[msg.sender] == 0) return 0;
        return (userCurrentRewards[msg.sender] + ((userStaked[msg.sender] * rewardsPerSecond * (block.timestamp - userStakedTimestamp[msg.sender])) / rewardsDenominator));
    }

    function rescueStakeTokens() external onlyOwner{
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function rescueRewardsTokens() external onlyOwner{
        rewardsToken.transfer(owner, rewardsToken.balanceOf(address(this)));
    }

    function setRewardsPerSecond(uint newRewardsPerSecond) external onlyOwner{
        rewardsPerSecond = newRewardsPerSecond;
    }

    function setRewardsDenominator(uint newRewardsDenominator) external onlyOwner{
        rewardsDenominator = newRewardsDenominator;
    }

    function transferOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }
}