// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Staking.sol";
import "./IOrionVoting.sol";
import "./ITWBalance.sol";
import "./IveORN.sol";

//import "./console.sol";

contract StakingReward is Staking
{
    uint128 constant YEAR = 365 * 86400;
    uint256 constant MAXTIME = 2 * YEAR;

    uint256 constant internal BOOST_PRECISION=1e18;
    uint128 public constant  MAX_LOCK_MULTIPLIER = 2;
    uint128 public constant  MAX_VEORN_MULTIPLIER = 2;
    uint128 public constant  MAX_BOOSTED_REWARD = 4;

    struct UserStateTime
    {
        uint48 lock_start;
        uint48 lock_period;
        bool   staking;

        ITWBalance.TWItem balanceTW;
        ITWBalance.TWItem totalTW;
    }

    uint256 public usedRewardForRate;//учтенная награда при расчете курса
    mapping(address => UserStateTime) public poolTimeStake;//временные метки лока по пользователям

    address public parentSmart;
    address public tokenStake;
    address public immutable smartVote;
    address public immutable veORN;

    event Deposit(address indexed provider, uint256 value, uint256 indexed lock_period, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event ClaimReward2(address indexed provider, uint256 value, uint256 originValue, uint256 ts);

    modifier onlyOwner() {
        require(msg.sender == parentSmart, "Caller is not the owner");
        _;
    }

    
    constructor(address _smartVote)
    {
        smartVote=_smartVote;
        veORN=IOrionVoting(_smartVote).veORN();
    }
    
    function init(address _token) external
    {
        require(parentSmart==address(0),"StakingReward: Was init");

        parentSmart=msg.sender;
        tokenStake=_token;
        /*smartVote=_smartVote;
        veORN=IOrionVoting(_smartVote).veORN();
        */
    }


    //override
    function calcNewRate() public override view returns (uint256)
    {
        uint256 Rate=0;
        if(allStake>0)
        {
            uint256 rewardPool=IOrionVoting(smartVote).getRewardCumulative(tokenStake);

            //отнимаем уже учтенную награду при расчете курса
            rewardPool -= usedRewardForRate;

            Rate=RATE_PRECISION*rewardPool/allStake;
        }

        return Rate;
    }
    function _writeCumulative() override internal
    {
        super._writeCumulative();
        usedRewardForRate=IOrionVoting(smartVote).getRewardCumulative(tokenStake);
    }

    function getReward(address account) public override view returns (uint256)
    {
        uint256 Reward = super.getReward(account) / (MAX_BOOSTED_REWARD+1);

        uint256 Boost = getBoost(account);

        return Boost  * Reward / BOOST_PRECISION;
    }


    //external
    function stake(address account, uint256 amount, uint256 lock_period) onlyOwner external returns(uint256 reward)
    {
        require(IOrionVoting(smartVote).havePool(tokenStake),"Pool not found in voting");

        reward = __claimReward(account);

        bool needWrite=false;
        UserStateTime memory item=poolTimeStake[account];
        if(lock_period>0)
        {
            require(lock_period <= MAXTIME, "Staking lock can be 2 years max");
            //require(amount>0 || getStake(account)>0, "Staking amount is zero");

            if(item.lock_period>0)
            {
                //уже был лок, проверяем что конечная дата не уменьшилась
                uint256 timeLockWas = item.lock_start + item.lock_period;
                uint256 timeLockNew = block.timestamp + lock_period;

                require(timeLockNew >= timeLockWas, "Can only increase lock duration");
            }

            item.lock_start = uint48(block.timestamp);
            item.lock_period = uint48(lock_period);
            needWrite=true;
        }


        if(!item.staking)
        {
            //при первом стейкинге запоминаем TW параметры для расчета среднего баланса
            item.balanceTW = IveORN(veORN).balanceOfTW(account);
            item.totalTW = IveORN(veORN).totalSupplyTW();
            item.staking=true;
            needWrite=true;
        }

        if(needWrite)
        {
            poolTimeStake[account]=item;
        }


        if(amount>0)
        {
            _stake(account, amount);
        }
        emit Deposit(account, amount, lock_period, block.timestamp);
    }

    function withdraw(address account) onlyOwner external returns(uint256 reward, uint256 amount)
    {
        UserStateTime memory item=poolTimeStake[account];
        require(item.lock_period == 0 || item.lock_start + item.lock_period <= block.timestamp,"The lock didn't expire");

        reward = __claimReward(account);
        amount = getStake(account);

        _unstake(account, amount);

        delete poolStake[account];
        delete poolTimeStake[account];

        emit Withdraw(account, amount, block.timestamp);
    }

    function claimReward(address account) onlyOwner  external returns(uint256)
    {
        return __claimReward(account);
    }

    //internal
    function __claimReward(address account) internal returns(uint256 reward)
    {
        reward=getReward(account);//reward with boost
        if(reward>0)
        {
            uint256 originReward=super.getReward(account);
            _claimReward(account, originReward);

            uint256 _useRewardAdd = originReward-reward;

            //добавляем нераспределенную награду бустинга
            usedRewardForRate -= _useRewardAdd; //usedRewardForRate всегда больше _useRewardAdd
            emit ClaimReward2(account, reward, originReward, block.timestamp);
        }
    }

    //View

    function getBoost(address account) public view returns (uint256)
    {
        UserStateTime memory item=poolTimeStake[account];

        uint256 totalLiquidity = allStake;
        uint256 totalVeORN=IveORN(veORN).totalSupplyAvg(item.totalTW);
        uint256 currentPoolReward=IOrionVoting(smartVote).getRewardCumulative(tokenStake);
        uint256 BoostVeORN=0;
        if(totalVeORN>0 && totalLiquidity>0 && currentPoolReward>0)
        {
            uint256 currentLiquidity = getStake(account);
            uint256 currentVeORN=IveORN(veORN).balanceOfAvg(account, item.balanceTW);

            uint256 totalReward=IOrionVoting(smartVote).getRewardCumulativeAll();

            uint256 KVeorn=BOOST_PRECISION*currentVeORN/totalVeORN;
            uint256 KLiquidity=BOOST_PRECISION*currentLiquidity/totalLiquidity;

            if(KLiquidity>0)
            {
                uint256 KPoolReverse = BOOST_PRECISION*totalReward/currentPoolReward;
                BoostVeORN = KVeorn*KPoolReverse*MAX_VEORN_MULTIPLIER/KLiquidity;
                if(BoostVeORN > MAX_VEORN_MULTIPLIER*BOOST_PRECISION)
                    BoostVeORN = MAX_VEORN_MULTIPLIER*BOOST_PRECISION;
            }
        }

        uint256 BoostStaking = MAX_LOCK_MULTIPLIER*BOOST_PRECISION*item.lock_period/MAXTIME;

        return BoostVeORN + BoostStaking + BOOST_PRECISION;
    }


    function lockTimeStart(address account) external view returns (uint48)
    {
        return poolTimeStake[account].lock_start;
    }
    function lockTimePeriod(address account) external view returns (uint48)
    {
        return poolTimeStake[account].lock_period;
    }


}