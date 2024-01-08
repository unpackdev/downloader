// SPDX-License-Identifier: MIT

// _________  ________  ________  _________
//|\___   ___\\   __  \|\   __  \|\___   ___\
//\|___ \  \_\ \  \|\ /\ \  \|\  \|___ \  \_|
//     \ \  \ \ \   __  \ \  \\\  \   \ \  \
//      \ \  \ \ \  \|\  \ \  \\\  \   \ \  \
//       \ \__\ \ \_______\ \_______\   \ \__\
//        \|__|  \|_______|\|_______|    \|__|

pragma solidity ^0.8;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ABDKMathQuad.sol";

contract StakingRewards is Ownable{
    using SafeMath for uint256;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 public apy = 95e16; // 100e16 is 100% a year
    uint256 public timeLock = 60 * 86400; // 1 day - 86400 seconds
    bool public locked = false;

    uint256 private fee = 10000000000000000; // 0.01 eth

    mapping(address => uint256) public rewardsPaid;
    mapping(address => uint256) public rewardsEarned;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lastUpdateTime;
    mapping(address => uint256) private _lastStakeTime;

    event Staking(address account, uint256 amount);
    event Unstaking(address account, uint256 amount);
    event Redeem(address account, uint256 amount);
    event RewardsLost(address account, uint256 amount);

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function changeAPY(uint256 newApy) external onlyOwner{
        apy = newApy;
    }

    function changeFee(uint256 newFee) external onlyOwner{
        fee = newFee;
    }

    function changeTimeLock(uint256 newTimeLock) external onlyOwner{
        timeLock = newTimeLock;
    }

    function changeLock(bool newLock) external onlyOwner{
        locked = newLock;
    }

    function rewardPerToken(address account) private view returns (uint256) {
        return
            ABDKMathQuad.toUInt (
                ABDKMathQuad.mul(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.sub(
                            ABDKMathQuad.fromUInt (block.timestamp),
                            ABDKMathQuad.fromUInt (_lastUpdateTime[account])
                        ),
                        ABDKMathQuad.div (
                            ABDKMathQuad.fromUInt (apy),
                            ABDKMathQuad.fromUInt (31536000*1e18)
                        )
                    ),
                    ABDKMathQuad.fromUInt (_balances[account])
                )
            );
    }

    function isTimeLocked(address account) private view returns(bool){
        uint256 timer = block.timestamp - _lastStakeTime[account];
        if(timer < timeLock){
            return true;
        }
        return false;
    }

    modifier updateReward(address account) {
        uint256 myRewardPerToken = rewardPerToken(account);
        _lastUpdateTime[account] = block.timestamp;
        rewardsEarned[account] += myRewardPerToken;
        _;
    }

    modifier isLocked(){
        require(!locked, "Sorry, the contract is locked");
        _;
    }

    function stake(uint256 _amount) external isLocked() updateReward(msg.sender) {
        _lastStakeTime[msg.sender] = block.timestamp;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        _balances[msg.sender] += _amount;
        emit Staking(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external isLocked() updateReward(msg.sender) {
        if(isTimeLocked(msg.sender)){
            emit RewardsLost(msg.sender, totalRewards(msg.sender));
            rewardsEarned[msg.sender] = 0;
        }
        _lastStakeTime[msg.sender] = block.timestamp;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Unstaking(msg.sender, _amount);
    }

    function getReward() external payable isLocked() updateReward(msg.sender) {
        require(!isTimeLocked(msg.sender),"Your rewards are in time lock");
        require(msg.value >= fee, "Sorry, not enough fee");
        uint256 reward = rewardsEarned[msg.sender];
        _lastStakeTime[msg.sender] = block.timestamp;
        rewardsEarned[msg.sender] = 0;
        rewardsPaid[msg.sender] += reward;
        rewardsToken.transfer(msg.sender, reward);
        emit Redeem(msg.sender, reward);
    }

    function totalRewards(address account) public view returns(uint256){
        uint256 myRewardPerToken = rewardPerToken(account);
        return  myRewardPerToken + rewardsEarned[account];
    }

    function balances(address account) external view returns(uint256){
        return _balances[account];
    }

    function timeToUnlock(address account) external view returns(uint256){
        uint256 timer = block.timestamp - _lastStakeTime[account];
        if(timer < timeLock){
            uint256 timeLeft = timeLock - timer;
            return timeLeft;
        }else{
            return 0;
        }
    }

    function transferFees(address payable _to) external onlyOwner {
        require(_to != address(0), "Zero Address");

        uint256 balance = address(this).balance;
        require(balance > 0, "Sorry, no balance");
        _to.transfer(balance);
    }

}