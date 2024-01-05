// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./console.sol";

contract MerchStaking is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct Stake {
        uint amount;
        uint startTime; 
        uint equivalentAmount;
        uint rewardOut;
    }

    // Info of each pool.
    struct Pool {
        uint stakingCap; // Pool staking tokens limit
        uint rewardCap; // Pool reward tokens limit
        uint rewardAPY; // scaled by 1e12
        uint startTime; 
        uint endTime; 
        uint stakedTotal; 
        uint tokenRate; // 1LP/MRCH scaled by 1e12
        bool bTimeLocked;
    }
    Pool[] public pools;

    mapping(uint => mapping(address => Stake)) public stakes;

    address public stakeToken; // Uniswap LP token from pool MRCH/USDT
    address public rewardToken; // MRCH token

    address public admin;

    event Staked(uint pid, address staker, uint amount);
    event RewardOut(uint pid, address staker, address token, uint amount);

    constructor(
        address _stakeToken,
        address _rewardToken
    ) {
        admin = msg.sender;

        require(_stakeToken != address(0), "MerchStaking: stake token address is 0");
        stakeToken = _stakeToken;

        require(_rewardToken != address(0), "MerchStaking: reward token address is 0");
        rewardToken = _rewardToken;
    }
    
    function addPool(uint _rewardCap, uint _rewardAPY, uint _startTime, uint _endTime,  uint _tokenRate, bool _bTimeLocked) public onlyOwner {
        // require(getTimeStamp() <= _startTime, "MerchStaking: bad timing for the request");
        require(_startTime < _endTime, "MerchStaking: endTime > startTime");
        
        uint equivalentStakeCap = calcStakeTokenEquivalent(_rewardCap, _tokenRate);

        pools.push(
            Pool({
            rewardCap: _rewardCap,
            stakingCap: equivalentStakeCap,
            rewardAPY: _rewardAPY,
            startTime: _startTime,
            endTime: _endTime,
            bTimeLocked: _bTimeLocked,
            tokenRate: _tokenRate,
            stakedTotal: 0
            })
        );
    }

    function stake(uint _pid, uint _amount) public returns (bool) {
        require(_amount > 0, "MerchStaking: must be positive");
        require(getTimeStamp() >= pools[_pid].startTime, "MerchStaking: bad timing for the request");
        require(getTimeStamp() < pools[_pid].endTime, "MerchStaking: bad timing for the request");

        address staker = msg.sender;

        require(pools[_pid].stakedTotal.add(_amount) <= pools[_pid].stakingCap, "MerchStaking: Staking cap is filled");
    
        transferIn(staker, stakeToken, _amount);

        emit Staked(_pid, staker, _amount);

        // Transfer is completed
        pools[_pid].stakedTotal = pools[_pid].stakedTotal.add(_amount);
        stakes[_pid][staker].amount = stakes[_pid][staker].amount.add(_amount);
        stakes[_pid][staker].equivalentAmount = calcRewardTokenEquivalent(_amount, pools[_pid].tokenRate);
        stakes[_pid][staker].startTime = getTimeStamp();
        stakes[_pid][staker].rewardOut = 0;

        return true;
    }

    function withdraw(uint _pid) public returns (bool) {
        require(pools[_pid].bTimeLocked == false, "MerchStaking: time lock pool");
        require(getTimeStamp() > pools[_pid].endTime || pools[_pid].bTimeLocked == false, "MerchStaking: time lock pool");
        require(claim(_pid), "MerchStaking: claim error");
        uint amount = stakes[_pid][msg.sender].amount;

        return withdrawWithoutReward(_pid, amount);
    }

    function withdrawWithoutReward(uint _pid, uint _amount) public returns (bool) {
        return withdrawInternal(_pid, msg.sender, _amount);
    }

    function withdrawInternal(uint _pid, address _staker, uint _amount) internal returns (bool) {
        require(_amount > 0, "MerchStaking: must be positive");
        require(_amount <= stakes[_pid][msg.sender].amount, "MerchStaking: not enough balance");

        stakes[_pid][_staker].amount = stakes[_pid][_staker].amount.sub(_amount);

        transferOut(stakeToken, _staker, _amount);

        return true;
    }

    function claim(uint _pid) public returns (bool) {
        require(pools[_pid].bTimeLocked == false || getTimeStamp() > pools[_pid].endTime, "MerchStaking: bad timing for the request");
        address staker = msg.sender;
        
        uint rewardAmount = currentReward(_pid, staker);

        if (rewardAmount == 0) {
            return true;
        }

        transferOut(rewardToken, staker, rewardAmount);

        stakes[_pid][staker].rewardOut = stakes[_pid][staker].rewardOut.add(rewardAmount);

        emit RewardOut(_pid, staker, rewardToken, rewardAmount);

        return true;
    }

    function currentReward(uint _pid, address _staker) public view returns (uint) {
        uint totalRewardAmount = stakes[_pid][_staker].equivalentAmount.mul(pools[_pid].rewardAPY).div(1e12).div(100);
        uint totalDuration = pools[_pid].endTime - stakes[_pid][_staker].startTime;
        uint duration = (getTimeStamp() > pools[_pid].endTime ? pools[_pid].endTime : getTimeStamp()) - stakes[_pid][_staker].startTime;
        
        uint rewardAmount = totalRewardAmount.mul(duration).div(totalDuration);
        
        return rewardAmount.sub(stakes[_pid][_staker].rewardOut);
    }

    function calcStakeTokenEquivalent(uint _amount, uint _tokenRate) public view returns (uint) {
        uint decimalsRewardToken = ERC20(rewardToken).decimals();
        uint decimalsStakeToken = ERC20(stakeToken).decimals();
        return _amount.mul(decimalsRewardToken).mul(1e12).div(_tokenRate).div(decimalsStakeToken);
    }

    function calcRewardTokenEquivalent(uint _amount, uint _tokenRate /* 1LP/MRCH */) public view returns (uint) {
        uint decimalsStakeToken = ERC20(stakeToken).decimals();
        uint decimalsRewardToken = ERC20(rewardToken).decimals();
        return _amount.mul(decimalsStakeToken).mul(_tokenRate).div(1e12).div(decimalsRewardToken);
    }

    function transferOut(address _token, address _to, uint _amount) internal {
        if (_amount == 0) {
            return;
        }

        IERC20 ERC20Interface = IERC20(_token);
        ERC20Interface.safeTransfer(_to, _amount);
    }

    function transferIn(address _from, address _token, uint _amount) internal {
        IERC20 ERC20Interface = IERC20(_token);
        ERC20Interface.safeTransferFrom(_from, address(this), _amount);
    }

    function transferTokens(address _token, address _to, uint _amount) public onlyOwner {
        if (_amount == 0) {
            return;
        }

        IERC20 ERC20Interface = IERC20(_token);
        ERC20Interface.safeTransfer(_to, _amount);
    }

    function getTimeStamp() public view virtual returns (uint) {
        return block.timestamp;
    }
}