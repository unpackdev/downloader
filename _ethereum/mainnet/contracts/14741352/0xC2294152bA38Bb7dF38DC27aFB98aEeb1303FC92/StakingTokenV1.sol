// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "./ARDImplementationV1.sol";
import "./Checkpoints.sol";
//import "./console.sol";

/**
 * @title Staking Token (STK)
 * @author Gheis Mohammadi
 * @dev Implements a staking Protocol using ARD token.
 */
contract StakingTokenV1 is ARDImplementationV1 {
    using SafeMath for uint256;
    using SafeMath for uint64;

    /*****************************************************************
    ** STRUCTS & VARIABLES                                          **
    ******************************************************************/
    struct Stake {
        uint256 id;
        uint256 stakedAt; 
        uint256 value;
        uint64  lockPeriod;
    }

    struct StakeHolder {
        uint256 totalStaked;
        Stake[] stakes;
    }

    struct Rate {
        uint256 timestamp;
        uint256 rate;
    }

    struct RateHistory {
        Rate[] rates;
    }

    /*****************************************************************
    ** STATES                                                       **
    ******************************************************************/
    /**
     * @dev token bank for storing the punishments
     */
    address internal tokenBank;

    /**
     * @dev start/stop staking protocol
     */
    bool internal stakingEnabled;
    
    /**
     * @dev start/stop staking protocol
     */
    bool internal earlyUnstakingAllowed;

    /**
     * @dev The minimum amount of tokens to stake
     */
    uint256 internal minStake;

    /**
     * @dev The id of the last stake
     */
    uint256 internal _lastStakeID;

    /**
     * @dev staking history
     */
    Checkpoints.History internal totalStakedHistory;

    /**
     * @dev stakeholder address map to stakes records details.
     */
    mapping(address => StakeHolder) internal stakeholders;

    /**
     * @dev The reward rate history per locking period
     */
    mapping(uint256 => RateHistory) internal rewardTable;
     /**
     * @dev The punishment rate history per locking period 
     */
    mapping(uint256 => RateHistory) internal punishmentTable;


    /*****************************************************************
    ** MODIFIERS                                                    **
    ******************************************************************/
    modifier onlyActiveStaking() {
        require(stakingEnabled, "staking protocol stopped");
        _;
    }

    /*****************************************************************
    ** EVENTS                                                       **
    ******************************************************************/
    // staking/unstaking events
    event Staked(address indexed from, uint256 amount, uint256 newStake, uint256 oldStake);
    event Unstaked(address indexed from, uint256 amount, uint256 newStake, uint256 oldStake);
    // events for adding or changing reward/punishment rate
    event RewardRateChanged(uint256 timestamp, uint256 newRate, uint256 oldRate);
    event PunishmentRateChanged(uint256 timestamp, uint256 newRate, uint256 oldRate);
    // events for staking start/stop
    event StakingStatusChanged(bool _enabled);
    // events for stop early unstaking
    event earlyUnstakingAllowanceChanged(bool _isAllowed);
    /*****************************************************************
    ** FUNCTIONALITY                                                **
    ******************************************************************/
    /**
     * This constructor serves the purpose of leaving the implementation contract in an initialized state, 
     * which is a mitigation against certain potential attacks. An uncontrolled implementation
     * contract might lead to misleading state for users who accidentally interact with it.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        //initialize(name_,symbol_);
        _pause();
    }

    /**
     * @dev initials tokens, roles, staking settings and so on.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    function initialize(string memory name_, string memory symbol_, address newowner_) public initializer{
        _initialize(name_, symbol_, newowner_);
        
        // contract can mint the rewards
        _setupRole(MINTER_ROLE, address(this));

        // set last stake id
        _lastStakeID = 0;

        // disable staking by default
        stakingEnabled=false;

        // disable early unstaking by default
        earlyUnstakingAllowed=false;

        // set default minimum allowed staking to 500 ARD
        minStake=500000000;

        // set default token bank
        tokenBank=0x2a2e06169b9BF7F611b518185CEf7c3740CdAeeE;

        /*
        set default rewards
        ---------------------
        | period |   rate   |
        ---------------------
        | 30     |   0.25%  |
        | 90     |   1.00%  |
        | 180    |   2.50%  |
        | 360    |   6.00%  |
        ---------------------
        */
        _setReward(30,   25);
        _setReward(90,   100);
        _setReward(180,  250);
        _setReward(360,  600);

        /*
        set default punishments
        ---------------------
        | period |   rate   |
        ---------------------
        | 30     |  12.50%  |
        | 90     |  12.50%  |
        | 180    |  12.50%  |
        | 360    |  12.50%  |
        ---------------------
        */
        _setPunishment(30,   1250);
        _setPunishment(90,   1250);
        _setPunishment(180,  1250);
        _setPunishment(360,  1250);
    }

    /**
     * @dev set token bank account address
     * @param _tb address of the token bank account 
    */
    function setTokenBank(address _tb)
        public
        notPaused
        onlySupplyController
    {
        tokenBank=_tb;
    }

    /**
     * @dev set token bank account address
     * @return address of the token bank account 
    */
    function getTokenBank()
        public
        view
        returns(address)
    {
        return tokenBank;
    }    
    
    ///////////////////////////////////////////////////////////////////////
    // STAKING                                                           //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev enable/disable stoking
     * @param _enabled enable/disable
    */
    function enableStakingProtocol(bool _enabled)
        public
        notPaused
        onlySupplyController
    {
        require(stakingEnabled!=_enabled, "same as it is");
        stakingEnabled=_enabled;
        emit StakingStatusChanged(_enabled);
    }

    /**
     * @dev enable/disable stoking
     * @return bool wheter staking protocol is enabled or not
    */
    function isStakingProtocolEnabled()
        public
        view
        returns(bool)
    {
        return stakingEnabled;
    }

    /**
     * @dev enable/disable early unstaking
     * @param _enabled enable/disable
    */
    function enableEarlyUnstaking(bool _enabled)
        public
        notPaused
        onlySupplyController
    {
        require(earlyUnstakingAllowed!=_enabled, "same as it is");
        earlyUnstakingAllowed=_enabled;
        emit earlyUnstakingAllowanceChanged(_enabled);
    }

    /**
     * @dev check whether unstoking is allowed
     * @return bool wheter unstaking protocol is allowed or not
    */
    function isEarlyUnstakingAllowed()
        public
        view
        returns(bool)
    {
        return earlyUnstakingAllowed;
    }

    /**
     * @dev set the minimum acceptable amount of tokens to stake
     * @param _minStake minimum token amount to stake
    */
    function setMinimumStake(uint256 _minStake)
        public
        notPaused
        onlySupplyController
    {
        minStake=_minStake;
    }

    /**
     * @dev get the minimum acceptable amount of tokens to stake
     * @return uint256 minimum token amount to stake
    */
    function minimumAllowedStake()
        public
        view 
        returns (uint256)
    {
        return minStake;
    }

    /**
     * @dev A method for a stakeholder to create a stake.
     * @param _value The size of the stake to be created.
     * @param _lockPeriod the period of lock for this stake
     * @return uint256 new stake id 
    */
    function stake(uint256 _value, uint64 _lockPeriod)
        public
        returns(uint256)
    {
        return _stake(_msgSender(), _value, _lockPeriod);
    }
    /**
     * @dev A method to create a stake in behalf of a stakeholder.
     * @param _stakeholder address of the stake holder
     * @param _value The size of the stake to be created.
     * @param _lockPeriod the period of lock for this stake
     * @return uint256 new stake id 
     */
    function stakeFor(address _stakeholder, uint256 _value, uint64 _lockPeriod)
        public
        onlySupplyController
        returns(uint256)
    {
        return _stake(_stakeholder, _value, _lockPeriod);
    }

    /**
     * @dev A method for a stakeholder to remove a stake.
     * @param _stakedID id number of the stake
     * @param _value The size of the stake to be removed.
     */
    function unstake(uint256 _stakedID, uint256 _value)
        public
    {
        _unstake(_msgSender(),_stakedID,_value);
    }

    /**
     * @dev A method for supply controller to remove a stake of a stakeholder.
     * @param _stakeholder The stakeholder to unstake his tokens.
     * @param _stakedID The unique id of the stake
     * @param _value The size of the stake to be removed.
     */
    function unstakeFor(address _stakeholder, uint256 _stakedID, uint256 _value)
        public
        onlySupplyController
    {
        _unstake(_stakeholder,_stakedID,_value);
    }

    /**
     * @dev A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakeholders[_stakeholder].totalStaked;
    }

    /**
     * @dev A method to retrieve the stakes for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return stakes history of the stake holder. 
     */
    function stakes(address _stakeholder)
        public
        view
        returns(Stake[] memory)
    {
        return(stakeholders[_stakeholder].stakes);
    }

    /**
     * @dev A method to get the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        return Checkpoints.latest(totalStakedHistory);
    }

    /**
     * @dev A method to get the value of total locked stakes.
     * @return uint256 The total locked stakes.
     */
    function totalValueLocked()
        public
        view
        returns(uint256)
    {
        return Checkpoints.latest(totalStakedHistory);
    }

    /**
     * @dev Returns the value in the latest stakes history, or zero if there are no stakes.
     * @param _stakeholder The stakeholder to retrieve the latest stake amount.
     */
    function latest(address _stakeholder) 
        public 
        view 
        returns (uint256) 
    {
        uint256 pos = stakeholders[_stakeholder].stakes.length;
        return pos == 0 ? 0 : stakeholders[_stakeholder].stakes[pos - 1].value;
    }

    /**
     * @dev Stakes _value for a stake holder. It pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * @return uint256 new stake id 
     */
    function _stake(address _stakeholder, uint256 _value, uint64 _lockPeriod) 
        internal
        notPaused
        onlyActiveStaking
        returns(uint256)
    {
        //_burn(_msgSender(), _stake);
        require(_stakeholder!=address(0),"zero account");
        require(_value >= minStake, "less than minimum stake");
        require(_value<=balanceOf(_stakeholder), "not enough balance");
        require(rewardTable[_lockPeriod].rates.length > 0, "invalid period");
        require(punishmentTable[_lockPeriod].rates.length > 0, "invalid period");

        _transfer(_stakeholder, address(this), _value);
        //if(stakeholders[_msgSender()].totalStaked == 0) addStakeholder(_msgSender());
        
        uint256 pos = stakeholders[_stakeholder].stakes.length;
        uint256 old = stakeholders[_stakeholder].totalStaked;
        if (pos > 0 && stakeholders[_stakeholder].stakes[pos - 1].stakedAt == block.timestamp && 
            stakeholders[_stakeholder].stakes[pos - 1].lockPeriod == _lockPeriod) {
                stakeholders[_stakeholder].stakes[pos - 1].value = stakeholders[_stakeholder].stakes[pos - 1].value.add(_value);
        } else {
            // uint256 _id = 1;
            // if (pos > 0) _id = stakeholders[_stakeholder].stakes[pos - 1].id.add(1);
            _lastStakeID++;
            stakeholders[_stakeholder].stakes.push(Stake({
                id: _lastStakeID,
                stakedAt: block.timestamp,
                value: _value,
                lockPeriod: _lockPeriod
            }));
            pos++;
        }
        stakeholders[_stakeholder].totalStaked = stakeholders[_stakeholder].totalStaked.add(_value);
        // checkpoint total supply
        _updateTotalStaked(_value, true);

        emit Staked(_stakeholder,_value, stakeholders[_stakeholder].totalStaked, old);
        return(stakeholders[_stakeholder].stakes[pos-1].id);
    }

    /**
     * @dev Unstake _value from specific stake for a stake holder. It calculate the reward/punishment as well.
     * It pushes a value onto a History so that it is stored as the checkpoint for the current block.
     * Returns previous value and new value.
     */
    function _unstake(address _stakeholder, uint256 _stakedID, uint256 _value) 
        internal 
        notPaused
        onlyActiveStaking
    {
        //_burn(_msgSender(), _stake);
        require(_stakeholder!=address(0),"zero account");
        require(_value > 0, "zero unstake");
        require(_value <= stakeOf(_stakeholder) , "unstake more than staked");
        
        uint256 old = stakeholders[_stakeholder].totalStaked;
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        uint256 stakeIndex;
        bool found = false;
        for (stakeIndex = 0; stakeIndex < stakeholders[_stakeholder].stakes.length; stakeIndex += 1){
            if (stakeholders[_stakeholder].stakes[stakeIndex].id == _stakedID) {
                found = true;
                break;
            }
        }
        require(found,"invalid stake id");
        require(_value<=stakeholders[_stakeholder].stakes[stakeIndex].value,"not enough stake");
        uint256 _stakedAt = stakeholders[_stakeholder].stakes[stakeIndex].stakedAt;
        require(block.timestamp>=_stakedAt,"invalid stake");
        // make decision about reward/punishment
        uint256 stakingDays = (block.timestamp - _stakedAt) / (1 days);
        if (stakingDays>=stakeholders[_stakeholder].stakes[stakeIndex].lockPeriod) {
            //Reward
            uint256 _reward = _calculateReward(_stakedAt, block.timestamp, 
                _value, stakeholders[_stakeholder].stakes[stakeIndex].lockPeriod);
            if (_reward>0) {
                _mint(_stakeholder,_reward);
            }
            _transfer(address(this), _stakeholder, _value);
        } else {
            //Punishment
            require (earlyUnstakingAllowed, "early unstaking disabled");
            uint256 _punishment = _calculatePunishment(_stakedAt, block.timestamp, 
                _value, stakeholders[_stakeholder].stakes[stakeIndex].lockPeriod);
            _punishment = _punishment<_value ? _punishment : _value;
            //If there is punishment, send them to token bank
            if (_punishment>0) {
                _transfer(address(this), tokenBank, _punishment); 
            }
            uint256 withdrawal = _value.sub( _punishment );
            if (withdrawal>0) {
                _transfer(address(this), _stakeholder, withdrawal);
            }
        }

        // deduct unstaked amount from locked ARDs
        stakeholders[_stakeholder].stakes[stakeIndex].value = stakeholders[_stakeholder].stakes[stakeIndex].value.sub(_value);
        if (stakeholders[_stakeholder].stakes[stakeIndex].value==0) {
            removeStakeRecord(_stakeholder, stakeIndex);
        }
        stakeholders[_stakeholder].totalStaked = stakeholders[_stakeholder].totalStaked.sub(_value);

        // checkpoint total supply
        _updateTotalStaked(_value, false);

        //if no any stakes, remove stake holder
        if (stakeholders[_stakeholder].totalStaked==0) {
           delete stakeholders[_stakeholder];
        }

        emit Unstaked(_stakeholder, _value, stakeholders[_stakeholder].totalStaked, old);
    }

    /**
     * @dev removes a record from the stake array of a specific stake holder
     * @param _stakeholder The stakeholder to remove stake from.
     * @param index the stake index (uinque ID)
     * Returns previous value and new value.
     */
    function removeStakeRecord(address _stakeholder, uint index) 
        internal 
    {
        for(uint i = index; i < stakeholders[_stakeholder].stakes.length-1; i++){
            stakeholders[_stakeholder].stakes[i] = stakeholders[_stakeholder].stakes[i+1];      
        }
        stakeholders[_stakeholder].stakes.pop();
    }

    /**
     * @dev update the total stakes history
     * @param _by The amount of stake to be added or deducted from history
     * @param _increase true means new staked is added to history and false means it's unstake and stake should be deducted from history
     * Returns previous value and new value.
     */
    function _updateTotalStaked(uint256 _by, bool _increase) 
        internal 
        onlyActiveStaking
    {
        uint256 currentStake = Checkpoints.latest(totalStakedHistory);

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            newStake = currentStake.sub(_by);
        }

        // add new value to total history
        Checkpoints.push(totalStakedHistory, newStake);
    }

    /**
     * @dev A method to get last stake id.
     * @return uint256 returns the ID of last stake
     */
    function lastStakeID()
        public
        view
        returns(uint256)
    {
        return _lastStakeID;
    }
    ///////////////////////////////////////////////////////////////////////
    // STAKEHOLDERS                                                      //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool Whether the address is a stakeholder or not
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool)
    {
        return (stakeholders[_address].totalStaked>0);
    }

    ///////////////////////////////////////////////////////////////////////
    // REWARDS / PUNISHMENTS                                             //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev set reward rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The reward per entire period for the given lock period
    */
    function setReward(uint256 _lockPeriod, uint64 _value)
        public
        notPaused
        onlySupplyController
    {
        _setReward(_lockPeriod,_value);
    }

    /**
     * @dev A method for adjust rewards table by single call. Should be called after first deployment.
     * this method merges the new table with current reward table (if it is existed)
     * @param _rtbl reward table ex:
     * const rewards = [
     *       [30,  200],
     *       [60,  300],
     *       [180, 500],
     *   ];
    */
    function setRewardTable(uint64[][] memory _rtbl)
        public
        notPaused
        onlySupplyController
    {
        for (uint64 _rIndex = 0; _rIndex<_rtbl.length; _rIndex++) {
            _setReward(_rtbl[_rIndex][0], _rtbl[_rIndex][1]);
        }
    }

    /**
     * @dev set reward rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The reward per entire period for the given lock period
    */
    function _setReward(uint256 _lockPeriod, uint64 _value)
        internal
    {
        require(_value>=0 && _value<=10000, "invalid rate");
        uint256 ratesCount = rewardTable[_lockPeriod].rates.length;
        uint256 oldRate = ratesCount>0 ? rewardTable[_lockPeriod].rates[ratesCount-1].rate : 0;
        require(_value!=oldRate, "duplicate rate");
        rewardTable[_lockPeriod].rates.push(Rate({
            timestamp: block.timestamp,
            rate: _value
        }));
        emit RewardRateChanged(block.timestamp,_value,oldRate);
    }

    /**
     * @dev A method for retrieve the latest reward rate for a give lock period
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function rewardRate(uint256 _lockPeriod)
        public
        view
        returns(uint256)
    {
        require(rewardTable[_lockPeriod].rates.length>0,"no rate");
        return _lastRate(rewardTable[_lockPeriod]);
    }

    /**
     * @dev A method for retrieve the history of the reward rate for a given lock period
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function rewardRateHistory(uint256 _lockPeriod)
        public
        view
        returns(RateHistory memory)
    {
        require(rewardTable[_lockPeriod].rates.length>0,"no rate");
        return rewardTable[_lockPeriod];
    }

    /**
     * @dev set punishment rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The punishment per entire period for the given lock period
    */
    function setPunishment(uint256 _lockPeriod, uint64 _value)
        public
        notPaused
        onlySupplyController
    {
        _setPunishment(_lockPeriod, _value);
    }

    /**
     * @dev A method for adjust punishment table by single call.
     * this method merges the new table with current punishment table (if it is existed)
     * @param _ptbl punishment table ex:
     * const punishments = [
     *       [30,  200],
     *       [60,  300],
     *       [180, 500],
     *   ];
    */
    function setPunishmentTable(uint64[][] memory _ptbl)
        public
        notPaused
        onlySupplyController
    {
        for (uint64 _pIndex = 0; _pIndex<_ptbl.length; _pIndex++) {
            _setPunishment(_ptbl[_pIndex][0], _ptbl[_pIndex][1]);
        }
    }

    /**
     * @dev set punishment rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The punishment per entire period for the given lock period
    */
    function _setPunishment(uint256 _lockPeriod, uint64 _value)
        internal
    {
        require(_value>=0 && _value<=2000, "invalid rate");
        uint256 ratesCount = punishmentTable[_lockPeriod].rates.length;
        uint256 oldRate = ratesCount>0 ? punishmentTable[_lockPeriod].rates[ratesCount-1].rate : 0;
        require(_value!=oldRate, "same as it is");
        punishmentTable[_lockPeriod].rates.push(Rate({
            timestamp: block.timestamp,
            rate: _value
        }));
        emit PunishmentRateChanged(block.timestamp,_value,oldRate);
    }

    /**
     * @dev A method to get the latest punishment rate
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function punishmentRate(uint256 _lockPeriod)
        public
        view
        returns(uint256)
    {
        require(punishmentTable[_lockPeriod].rates.length>0,"no rate");
        return _lastRate(punishmentTable[_lockPeriod]);
    }

    /**
     * @dev A method for retrieve the history of the punishment rate for a give lock period
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function punishmentRateHistory(uint256 _lockPeriod)
        public
        view
        returns(RateHistory memory)
    {
        require(punishmentTable[_lockPeriod].rates.length>0,"no rate");
        return punishmentTable[_lockPeriod];
    }

    /**
     * @dev A method to inquiry the rewards from the specific stake of the stakeholder.
     * @param _stakeholder The stakeholder to get the reward for his stake.
     * @param _stakedID The stake id.
     * @return uint256 The reward of the stake.
     */
    function rewardOf(address _stakeholder,  uint256 _stakedID)
        public
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        // uint256 _totalRewards = 0;
        // for (uint256 i = 0; i < stakeholders[_stakeholder].stakes.length; i++){
        //     Stake storage s = stakeholders[_stakeholder].stakes[i];
        //     uint256 r = _calculateReward(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
        //     _totalRewards = _totalRewards.add(r);
        // }
        // return _totalRewards;
        return calculateRewardFor(_stakeholder,_stakedID);
    }

    /**
     * @dev A method to inquiry the punishment from the early unstaking of the specific stake of the stakeholder.
     * @param _stakeholder The stakeholder to get the punishment for early unstake.
     * @param _stakedID The stake id.
     * @return uint256 The punishment of the early unstaking of the stake.
     */
    function punishmentOf(address _stakeholder,  uint256 _stakedID)
        public
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        // uint256 _totalPunishments = 0;
        // for (uint256 i = 0; i < stakeholders[_stakeholder].stakes.length; i++){
        //     Stake storage s = stakeholders[_stakeholder].stakes[i];
        //     uint256 r = _calculatePunishment(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
        //     _totalPunishments = _totalPunishments.add(r);
        // }
        // return _totalPunishments;
        return calculatePunishmentFor(_stakeholder,_stakedID);
    }

    /** 
     * @dev A simple method to calculate the rewards for a specific stake of a stakeholder.
     * The rewards only is available after stakeholder unstakes the ARDs.
     * @param _stakeholder The stakeholder to calculate rewards for.
     * @param _stakedID The stake id.
     * @return uint256 return the reward for the stake with specific ID.
     */
    function calculateRewardFor(address _stakeholder, uint256 _stakedID)
        internal
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        uint256 stakeIndex;
        bool found = false;
        for (stakeIndex = 0; stakeIndex < stakeholders[_stakeholder].stakes.length; stakeIndex += 1){
            if (stakeholders[_stakeholder].stakes[stakeIndex].id == _stakedID) {
                found = true;
                break;
            }
        }
        require(found,"invalid stake id");
        Stake storage s = stakeholders[_stakeholder].stakes[stakeIndex];
        return _calculateReward(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
    }

    /** 
     * @dev A simple method to calculates the reward for stakeholder from a given period which is set by _from and _to.
     * @param _from The start date of the period.
     * @param _to The end date of the period.
     * @param _value Amount of staking.
     * @param _lockPeriod lock period for this staking.
     * @return uint256 total reward for given period
     */
    function _calculateReward(uint256 _from, uint256 _to, uint256 _value, uint256 _lockPeriod)
        internal
        view
        returns(uint256)
    {
        require (_to>=_from,"invalid stake time");
        uint256 durationDays = _duration(_from,_to,_lockPeriod);
        if (durationDays<_lockPeriod) return 0;

        return _calculateTotal(rewardTable[_lockPeriod],_from,_to,_value,_lockPeriod);
    }

   /** 
     * @dev A simple method to calculate punishment for early unstaking of a specific stake of the stakeholder.
     * The punishment is only charges after stakeholder unstakes the ARDs.
     * @param _stakeholder The stakeholder to calculate punishment for.
     * @param _stakedID The stake id.
     * @return uint256 return the punishment for the stake with specific ID.
     */
    function calculatePunishmentFor(address _stakeholder, uint256 _stakedID)
        internal
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        uint256 stakeIndex;
        bool found = false;
        for (stakeIndex = 0; stakeIndex < stakeholders[_stakeholder].stakes.length; stakeIndex += 1){
            if (stakeholders[_stakeholder].stakes[stakeIndex].id == _stakedID) {
                found = true;
                break;
            }
        }
        require(found,"invalid stake id");
        Stake storage s = stakeholders[_stakeholder].stakes[stakeIndex];
        return _calculatePunishment(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
    }

    /** 
     * @dev A simple method that calculates the punishment for stakeholder from a given period which is set by _from and _to.
     * @param _from The start date of the period.
     * @param _to The end date of the period.
     * @param _value Amount of staking.
     * @param _lockPeriod lock period for this staking.
     * @return uint256 total punishment for given period
     */
    function _calculatePunishment(uint256 _from, uint256 _to, uint256 _value, uint256 _lockPeriod)
        internal
        view
        returns(uint256)
    {
        require (_to>=_from,"invalid stake time");
        uint256 durationDays = _to.sub(_from).div(1 days);
        if (durationDays>=_lockPeriod) return 0;
        // retrieve latest punishment rate for the lock period
        uint256 pos = punishmentTable[_lockPeriod].rates.length;
        require (pos>0, "invalid lock period");
        
        return _value.mul(punishmentTable[_lockPeriod].rates[pos-1].rate).div(10000); 
        //return _calculateTotal(punishmentTable[_lockPeriod],_from,_to,_value,_lockPeriod);
    }

    /** 
     * @dev calculates the total amount of reward/punishment for a given period which is set by _from and _to. This method calculates 
     * based on the history of rate changes. So if in this period, three times rate have had changed, this function calculates for each
     * of the rates separately and returns total 
     * @param _history The history of rates
     * @param _from The start date of the period.
     * @param _to The end date of the period.
     * @param _value Amount of staking.
     * @param _lockPeriod lock period for this staking.
     * @return uint256 total reward/punishment for given period considering the rate changes
     */
    function _calculateTotal(RateHistory storage _history, uint256 _from, uint256 _to, uint256 _value, uint256 _lockPeriod)
        internal
        view
        returns(uint256)
    {
        //find the first rate before _from 

        require(_history.rates.length>0,"invalid period");
        uint256 rIndex;
        for (rIndex = _history.rates.length-1; rIndex>0; rIndex-- ) {
            if (_history.rates[rIndex].timestamp<=_from) break;
        }
        require(_history.rates[rIndex].timestamp<=_from, "lack of history rates");
        // if rate has been constant during the staking period, just calculate whole period using same rate
        if (rIndex==_history.rates.length-1) {
            return _value.mul(_history.rates[rIndex].rate).div(10000);  //10000 ~ 100.00
        }
        // otherwise we have to calculate reward per each rate change record from history

        /*                                       [1.5%]             [5%]               [2%]
           Rate History:    (deployed)o(R0)----------------o(R1)-------------o(R2)-----------------o(R3)--------------------
           Given Period:                   o(from)--------------------------------------o(to)
           
           Calculations:     ( 1.5%*(R1-from) + 5%*(R2-R1) + 2%*(to-R2) ) / Period
        */
        uint256 total = 0;
        uint256 totalDuration = 0;
        uint256 prevTimestamp = _from;
        uint256 diff = 0;
        uint256 maxTotalDuration = _duration(_from,_to, _lockPeriod);
        for (rIndex++; rIndex<=_history.rates.length && totalDuration<maxTotalDuration; rIndex++) {
            
            if (rIndex<_history.rates.length){
                diff = _duration(prevTimestamp, _history.rates[rIndex].timestamp, 0);
                prevTimestamp = _history.rates[rIndex].timestamp;
            }else {
                diff = _duration(prevTimestamp, _to, 0);
                prevTimestamp = _to;
            }

            totalDuration = totalDuration.add(diff);
            if (totalDuration>maxTotalDuration) {
                diff = diff.sub(totalDuration.sub(maxTotalDuration));
                totalDuration = maxTotalDuration;
            }
            total = total.add(_history.rates[rIndex-1].rate.mul(diff));
        }
        return _value.mul(total).div(_lockPeriod.mul(10000));
    }

    /**
    * @dev this function calculates the number of days between t1 and t2
    * @param t1 the period start
    * @param t2 the period end
    * @param maxDuration max duration. if the number of days is more than max, it returns max 
    * @return uint256 number of days
     */
    function _duration(uint256 t1, uint256 t2, uint256 maxDuration)
        internal
        pure
        returns(uint256)
    {
        uint256 diffDays = t2.sub(t1).div(1 days);
        if (maxDuration==0) return diffDays;
        return Math.min(diffDays,maxDuration);
    }

    /**
    * @dev this function retrieve last rate of a given rate history
    * @param _history the history of rate changes
    * @return uint256 the last rate which is current rate
     */
    function _lastRate(RateHistory storage _history)
        internal
        view
        returns(uint256)
    {
        return _history.rates[_history.rates.length-1].rate;
    }

    // storage gap for adding new states in upgrades 
    uint256[50] private __gap;
}