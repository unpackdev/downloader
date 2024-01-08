// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IPLBTStaking.sol";
import "./IDAO.sol";

///@title Staking contract
contract PLBTStaking is IPLBTStaking, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Staker storage instance
    struct Staker {
        uint256 amount; // amount of tokens currently staked to the contract
        uint256 rewardGained; // increases every time staker unstakes their tokens. used to keep track of how much user earned before unstaking
        uint256 rewardMissed; // increases every time staker stakes more tokens. used to keep track of how much user missed before staking
        uint256 distributed; // total amount of reward tokens earned by the staker
    }
    
    // Staking information
    struct StakingInfo {
        uint256 _startTime; // staking start time
        uint256 _distributionTime; // period, over which _rewardTotal should be distributed
        uint256 _rewardTotalWBTC;
        uint256 _rewardTotalWETH;
        uint256 _totalStaked; // total amount of tokens currently staked on the contract
        uint256 _producedWETH; // total amount of produced wETH rewards
        uint256 _producedWBTC; // total amount of produced wBTC rewards
        address _PLBTAddress; // address of staking token
        address _wETHAddress; // address of reward token
        address _wBTCAddress; // address of reward token
    }


    // Map<address, staker> maps staker's information by their address
    mapping(address => Staker) private stakers;

    /// role of treasury holder
    bytes32 public TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // address of the treasury
    address treasury;

    // Staking token
    IERC20 private PLBT;

    // Reward tokens
    IERC20 private wBTC;
    IERC20 private wETH;

    // Staking configuration variables
    uint256 public rewardTotal; // total reward over distribution time
    uint256 public allProduced; // variable used to store value of produced rewards before changing rewardTotal
    uint256 public totalStaked; // total amount of currently staked tokens
    uint256 public totalDistributed; // total amount of tokens earned by stakers
    uint256 public totalWBTC; // total rewards in wBTC distributed over distibutionTime
    uint256 public totalWETH; // total rewards in wETH distributed over distributionTime
    uint256 public totalProducedWETH; // total produced rewards in wETH
    uint256 public totalProducedWBTC; // total produced rewards in wBTC

    uint256 private producedTime; // variable used  to store time when rewardTotal is changed
    uint256 private startTime; // staking's start time
    uint256 private immutable distributionTime; // period, over which rewardTotal is distributed
    uint256 private tokensPerStake; // reward token per staked token
    uint256 private rewardProduced; // total amount of produced reward tokens
    bool private initialized; //shows if staking is initialized
    
    //DAO address
    IDAO private DAO; // DAO contract

     ///@dev Emitted when user stake tokens 
    ///@param amount amount of staked tokens
    ///@param time current block.timestamp
    ///@param sender msg.sender addresss
    event Staked(uint256 amount, uint256 time, address indexed sender);

    ///@dev Emitted when user claims reward tokens
    ///@param amountWETH amount of claimed  wETH tokens
    ///@param amountWBTC amount of claimed wBTC  tokens
    ///@param time current block.timestamp
    ///@param sender msg.sender addresss
    event Claimed(uint256 amountWETH, uint amountWBTC, uint256 time, address indexed sender);

    ///@dev Emitted when user unstakes token
    ///@param amount amount of unstaked tokens
    ///@param time current block.timestamp
    ///@param sender msg.sender address
    event Unstaked(uint256 amount, uint256 time, address indexed sender);

   
    ///@param _distributionTime period, over which `_rewardTotal` is distributed
    constructor(uint256 _distributionTime  ){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TREASURY_ROLE, DEFAULT_ADMIN_ROLE);
        distributionTime = _distributionTime;
    }

     ///@dev Initializes Staking contract with tokens
    ///@param _startTime time when staking becomes active
     ///@param _wETH Wrapped Ethereum token address
     ///@param _wBTC Wrapped Bitcoin token address
     ///@param _PLBT PLBT Token address
     ///@param _addressDAO DAO address
    function initialize(uint256 _startTime, address _wETH, address _wBTC, address _PLBT, address _addressDAO, address _treasury) external  onlyRole(DEFAULT_ADMIN_ROLE){
        require(
            !initialized,
            "Staking: contract already initialized"
        );
        require(
            _startTime >= block.timestamp, 
            "Staking: current time greater than startTime"
        );
        startTime = _startTime;
        producedTime = _startTime;
        wETH = IERC20(_wETH);
        wBTC = IERC20(_wBTC);
        PLBT = IERC20(_PLBT);
        DAO = IDAO(_addressDAO);
        treasury = _treasury;
        _setupRole(TREASURY_ROLE, treasury);
        _setupRole(DEFAULT_ADMIN_ROLE, _addressDAO);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        initialized = true;
    }

    ///@dev retrieve reward leftovers
    function sweep() external onlyRole(TREASURY_ROLE){
        uint256 amountWETH = wETH.balanceOf(address(this));
        uint256 amountWBTC = wBTC.balanceOf(address(this));
        wETH.safeTransfer(treasury, amountWETH);
        wBTC.safeTransfer(treasury, amountWBTC);
    }

    ///@dev changes treasury address
    ///@param _treasury address of the treasury
    function changeTreasury(address _treasury) external override onlyRole(DEFAULT_ADMIN_ROLE){
        revokeRole(TREASURY_ROLE, treasury);
        treasury = _treasury;
        grantRole(TREASURY_ROLE, treasury);
    }

    ///@dev Sets amount of reward during `distributionTime`
    ///@param _amountWETH amount of rewards in wETH
    ///@param _amountWBTC amount of rewards in wBTC
    function setReward(uint256 _amountWETH, uint256 _amountWBTC) external  override onlyRole(DEFAULT_ADMIN_ROLE) {
        allProduced = produced();
        producedTime = block.timestamp;
        totalWBTC = _amountWBTC;
        totalWETH = _amountWETH;
        rewardTotal = _amountWETH + _amountWBTC;
    }

    ///@dev calculates available reward
    ///@param _staker address of the staker
    ///@param _tps reward tokens per staked tokens
    function calcReward(address _staker, uint256 _tps) private view returns (uint256 reward)
    {
        Staker storage staker = stakers[_staker];
        reward = staker.amount*_tps/1e20 + staker.rewardGained - staker.distributed - staker.rewardMissed;
        return reward;
    }

    ///@dev Calculates the total amount of currently produced reward
    ///@return current produced amount of reward tokens
    function produced() private view returns (uint256) {
        return allProduced + rewardTotal*(block.timestamp - producedTime)/distributionTime;
    }
    
    ///@dev updates produced reward. called  inside stake, unstake and claim functions
    function update() private {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalStaked > 0) {
                tokensPerStake = tokensPerStake+producedNew*1e20/totalStaked;
            }
            rewardProduced += producedNew;
        }
    }

    ///@notice transfers `_amount` staking tokens from staker to staking contract
    ///@param _amount amount of tokens to unstaket
    function stake(uint256 _amount) external {
        require(
            block.timestamp > startTime,
            "Staking: staking time has not come yet"
        );
        require(
            _amount > 0,
            "Staking: stake amount should be greater than 0"
        );
        Staker storage staker = stakers[msg.sender];
        PLBT.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        staker.rewardMissed += _amount*tokensPerStake/1e20;
        totalStaked += _amount;
        staker.amount += _amount;
        update();
        emit Staked(_amount, block.timestamp, msg.sender);
    }

    ///@notice transfers `_amount` of staking tokens back to the staker
    ///@param _amount amount of tokens to unstake
    function unstake(uint256 _amount) external  nonReentrant {
        require(
            _amount > 0,
            "Staking: unstake amount should be greater than 0"
        );
        Staker storage staker = stakers[msg.sender];
        uint256 locked = DAO.getLockedTokens(msg.sender);
        uint256 unstakable = staker.amount - locked;
        require(
             _amount <= unstakable, //staker can't unstake tokens used for voting
            "Staking: Not enough tokens to unstake"
        );
        update();

        staker.rewardGained += _amount*tokensPerStake/1e20;
        staker.amount  -= _amount;
        totalStaked -= _amount;

        PLBT.safeTransfer(msg.sender, _amount);

        emit Unstaked(_amount, block.timestamp, msg.sender);
    }

    ///@dev transfers reward tokens to the staker
    ///@return wETHReward  amount of claimed wETH
    ///@return wBTCReward amount of claimed wBTC
    function claim() external  nonReentrant returns (uint256 wETHReward, uint256 wBTCReward) {
        if (totalStaked > 0) {
            update();
        }
        uint256 reward = calcReward(msg.sender, tokensPerStake);
        require(reward > 0, "Staking: Nothing to claim");
        
        Staker storage staker = stakers[msg.sender];
        staker.distributed += reward;
        totalDistributed += reward;

        wETHReward  = (reward*totalWETH)/(rewardTotal);
        wBTCReward = (reward*totalWBTC)/(rewardTotal);
        wETH.safeTransfer(msg.sender, wETHReward);
        wBTC.safeTransfer(msg.sender, wBTCReward);
        emit Claimed(wETHReward, wBTCReward, block.timestamp, msg.sender);
        return  (wETHReward, wBTCReward);
    }

    ///@dev returns information about the stake
    ///@return info_ struct containing staking information
    function getStakingInfo() external view returns (StakingInfo memory info_) {
        uint256 producedAtNow = produced();
        uint256 producedWETH = (producedAtNow*totalWETH)/rewardTotal;
        uint256 producedWBTC = (producedAtNow*totalWBTC)/rewardTotal;
        info_ = StakingInfo({
            _startTime: startTime,
            _distributionTime: distributionTime,
            _rewardTotalWBTC: totalWBTC,
            _rewardTotalWETH: totalWETH,
            _totalStaked: totalStaked,
            _producedWETH: producedWETH,
            _producedWBTC: producedWBTC,
            _PLBTAddress: address(PLBT),
            _wETHAddress: address(wETH),
            _wBTCAddress: address(wBTC)
        });
        return info_;
    }

    ///@notice return staker's information by their `_address`
    ///@param _address address of the staker
    ///@return staked_ amount of tokens staked by the staker
    ///@return claimWETH_ awailable to claim amount of rewards in wETH
    ///@return claimWBTC_ awailable to claim amount of rewards in wBTC
    function getInfoByAddress(address _address) external view returns (
        uint256 staked_,
        uint256 claimWETH_,
        uint256 claimWBTC_
    ){
        Staker storage staker = stakers[_address];
        staked_ = staker.amount;
        uint256 _tps = tokensPerStake;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tps = _tps + producedNew*1e20/totalStaked;
            }
        }
        uint256 reward = calcReward(_address, _tps);
        claimWETH_  = (reward*totalWETH)/rewardTotal;
        claimWBTC_ = (reward*totalWBTC)/rewardTotal;
        return (staked_, claimWETH_, claimWBTC_);
    }

    function getStakedTokens(address _address) external view override returns (uint256){
        return stakers[_address].amount;
    }
}