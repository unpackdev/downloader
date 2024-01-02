// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "./console.sol";

abstract contract Staking
{
    uint256 constant internal RATE_PRECISION=1e40;

    uint256 public rewardRate;//скорость наград, например 1 ORN в секунду на всех (точность 10**48)

    struct UserState
    {
        uint256 stake;
        uint256 rateCumulative;
        uint256 reward;
        uint256 rewardWithdraw;
    }

    uint256 public allStake; //сумма всех стейков
    mapping(address => UserState) public poolStake;//стейки по пользователям

    uint256 public rateCumulative;
    uint256 public rateTime;
    uint256 private rewardCumulativeTotal;//сумма всех наград

    event SetRewards(uint64 rewards, uint64 duration, uint256 rewardCumulativeTotal, uint256 rateCumulative, uint256 timestamp);
    event Stake(address indexed account, uint256 amount, uint256 rewardCumulativeTotal, uint256 rateCumulative, uint256 reward, uint256 timestamp);
    event Unstake(address indexed account, uint256 amount, uint256 rewardCumulativeTotal, uint256 rateCumulative, uint256 reward, uint256 timestamp);
    event ClaimReward(address indexed account, uint256 amount, uint256 rewardCumulativeTotal, uint256 rateCumulative, uint256 reward, uint256 timestamp);
    

    //  Set the overall reward
    function _setRewards(uint64 rewards, uint64 duration) internal
    {
        require(duration > 0, "_setRewards: zero duration");

        _writeCumulative();

        //  ORN / sec
        rewardRate = RATE_PRECISION * rewards / duration;

        emit SetRewards(rewards, duration, rewardCumulativeTotal, rateCumulative, block.timestamp);
    }

    //Расчет нового курса награды
    function calcNewRate() public virtual view returns (uint256)
    {
        uint256 Rate=0;
        if(allStake>0)
        {
            Rate=rewardRate/allStake;
        }

        return Rate*(block.timestamp-rateTime);
    }

    function _writeCumulative() virtual internal
    {
        uint256 newRate = calcNewRate();

        rewardCumulativeTotal += newRate*allStake/RATE_PRECISION;
        rateCumulative += newRate;
        rateTime=block.timestamp;
    }

    function _stake(address account, uint256 amount) internal
    {
        require(amount>0,"_stake: zero stake amount");

        _writeCumulative();

        UserState memory item=poolStake[account];
        item.reward=_calcReward(item, rateCumulative);
        item.stake += amount;
        item.rateCumulative=rateCumulative;
        poolStake[account]=item;

        allStake += amount;

        emit Stake(account, amount, rewardCumulativeTotal, rateCumulative, item.reward, block.timestamp);
    }

    function _claimReward(address account, uint256 amount) internal
    {
        _writeCumulative();

        UserState memory item=poolStake[account];

        item.reward=_calcReward(item, rateCumulative);
        require(item.reward - item.rewardWithdraw >= amount,"Error claim amount");
        item.rewardWithdraw += amount;
        item.rateCumulative=rateCumulative;
        poolStake[account]=item;

        emit ClaimReward(account, amount, rewardCumulativeTotal, rateCumulative, item.reward, block.timestamp);
    }

    function _unstake(address account, uint256 amount) internal
    {
        _writeCumulative();

        UserState memory item=poolStake[account];
        require(item.stake >= amount,"Error unstake amount");
        
        item.reward=_calcReward(item, rateCumulative);
        item.stake -= amount;
        item.rateCumulative=rateCumulative;
        poolStake[account]=item;

        allStake -= amount;

        emit Unstake(account, amount, rewardCumulativeTotal, rateCumulative, item.reward, block.timestamp);
    }


    function _calcReward(UserState memory item, uint256 _rateCumulative) internal pure returns (uint256)
    {
        return item.reward + (_rateCumulative-item.rateCumulative)*item.stake/RATE_PRECISION;
    }

    function getReward(address account) public virtual view returns (uint256)
    {
        UserState memory item=poolStake[account];
        uint256 _rateCumulative = rateCumulative + calcNewRate();
        return _calcReward(item, _rateCumulative) - item.rewardWithdraw;
    }

    function getStake(address account) public view returns (uint256)
    {
        return poolStake[account].stake;
    }

    function getRewardWithdraw(address account) external view returns (uint256)
    {
        return poolStake[account].rewardWithdraw;
    }

    function getRewardCumulative(address account) external view returns (uint256)
    {
        return getReward(account) + poolStake[account].rewardWithdraw;
    }

    function getRewardCumulativeAll() public view returns (uint256)
    {
        uint256 newRate = calcNewRate();
        return rewardCumulativeTotal + newRate*allStake/RATE_PRECISION;
    }


}