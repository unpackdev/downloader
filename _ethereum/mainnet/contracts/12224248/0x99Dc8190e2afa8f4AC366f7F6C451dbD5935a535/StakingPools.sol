// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./FixedPointMath.sol";
import "./Pool.sol";
import "./Stake.sol";

import "./IRewardEscrow.sol";

/// @title StakingPools
//    ___    __        __                _               ___                              __         _ 
//   / _ |  / / ____  / /  ___   __ _   (_) __ __       / _ \  ____ ___   ___ ___   ___  / /_  ___  (_)
//  / __ | / / / __/ / _ \/ -_) /  ' \ / /  \ \ /      / ___/ / __// -_) (_-</ -_) / _ \/ __/ (_-< _   
// /_/ |_|/_/  \__/ /_//_/\__/ /_/_/_//_/  /_\_\      /_/    /_/   \__/ /___/\__/ /_//_/\__/ /___/(_)  
//  
//      _______..___________.     ___       __  ___  __  .__   __.   _______    .______     ______     ______    __           _______.
//     /       ||           |    /   \     |  |/  / |  | |  \ |  |  /  _____|   |   _  \   /  __  \   /  __  \  |  |         /       |
//    |   (----``---|  |----`   /  ^  \    |  '  /  |  | |   \|  | |  |  __     |  |_)  | |  |  |  | |  |  |  | |  |        |   (----`
//     \   \        |  |       /  /_\  \   |    <   |  | |  . `  | |  | |_ |    |   ___/  |  |  |  | |  |  |  | |  |         \   \    
// .----)   |       |  |      /  _____  \  |  .  \  |  | |  |\   | |  |__| |    |  |      |  `--'  | |  `--'  | |  `----..----)   |   
// |_______/        |__|     /__/     \__\ |__|\__\ |__| |__| \__|  \______|    | _|       \______/   \______/  |_______||_______/                                                                                                                                
///
/// @dev A contract which allows users to stake to farm tokens.
///
/// This contract was inspired by Chef Nomi's 'MasterChef' contract which can be found in this
/// repository: https://github.com/sushiswap/sushiswap.
contract StakingPools is ReentrancyGuard {
  using FixedPointMath for FixedPointMath.uq192x64;
  using Pool for Pool.Data;
  using Pool for Pool.List;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Stake for Stake.Data;

  event PendingGovernanceUpdated(
    address pendingGovernance
  );

  event GovernanceUpdated(
    address governance
  );

  event RewardRateUpdated(
    uint256 rewardRate
  );

  event ExitFeeReceiverUpdated(
    address indexed exitFeeReceiver
  );

  event PoolExitFeePercentageUpdated(
    uint256 indexed poolId,
    uint256 exitFeePercentage
  );

  event PoolRewardWeightUpdated(
    uint256 indexed poolId,
    uint256 rewardWeight
  );

  event PoolEscrowPercentageUpdated(
    uint256 indexed poolId,
    uint256 escrowPercentage
  );

  event PoolCreated(
    uint256 indexed poolId,
    IERC20 indexed token
  );

  event TokensDeposited(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event TokensWithdrawn(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event TokensClaimed(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event ReferrerSet(
    address indexed user,
    address indexed referrer
  );

  event ReferrerPaid(
    address indexed user,
    address indexed referrer,
    uint256 amount
  );

  event ReferrerClaimed(
    address indexed referrer,
    uint256 amount
  );

  /// @dev The token which will be minted as a reward for staking.
  IERC20 public reward;

  /// @dev The address receiving the exit fees
  address public exitFeeReceiver;

  /// @dev The Address where the tokens will be withdrawed from.
  address public rewardSource;

  /// @dev Reward Escrow contract
  IRewardEscrow rewardEscrow;

  /// @dev The address of the account which currently has administrative capabilities over this contract.
  address public governance;

  address public pendingGovernance;

  /// @dev Tokens are mapped to their pool identifier plus one. Tokens that do not have an associated pool
  /// will return an identifier of zero.
  mapping(IERC20 => uint256) public tokenPoolIds;

  /// @dev The context shared between the pools.
  Pool.Context private _ctx;

  /// @dev A list of all of the pools.
  Pool.List private _pools;

  /// @dev A mapping of all of the user stakes mapped first by pool and then by address.
  mapping(address => mapping(uint256 => Stake.Data)) private _stakes;

  /// @dev Who referred who
  mapping(address => address) public referrerOf;

  /// @dev Amount of referral rewards
  mapping(address => uint256) public referrerBalanceOf;

  /// @dev referral percentage of referrer
  mapping(address => uint256) public referralPercentageOf;

  /// @dev referral escrow percentage for the referrer
  mapping(address => uint256) public referralEscrowPercentageOf;


  function initialize(
    IERC20 _reward,
    address _rewardSource,
    address _exitFeeReceiver,
    IRewardEscrow _rewardEscrow,
    address _governance
  ) public {
    require(address(reward) == address(0), "StakingPools: already initialized");

    require(address(_reward) != address(0), "StakingPools: reward address cannot be 0x0");
    require(address(_rewardSource) != address(0), "StakingPools: reward source address cannot be 0x0");
    require(address(_exitFeeReceiver) != address(0), "StakingPools: exit fee receiver cannot be 0x0");
    require(address(_rewardEscrow) != address(0), "StakingPools: reward escrow cannot be 0x0");
    require(_governance != address(0), "StakingPools: governance address cannot be 0x0");

    reward = _reward;
    rewardSource = _rewardSource;
    exitFeeReceiver = _exitFeeReceiver;
    rewardEscrow = _rewardEscrow;
    governance = _governance;
  }

  /// @dev A modifier which reverts when the caller is not the governance.
  modifier onlyGovernance() {
    require(msg.sender == governance, "StakingPools: only governance");
    _;
  }

  /// @dev Sets the governance.
  ///
  /// This function can only called by the current governance.
  ///
  /// @param _pendingGovernance the new pending governance.
  function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
    require(_pendingGovernance != address(0), "StakingPools: pending governance address cannot be 0x0");
    pendingGovernance = _pendingGovernance;

    emit PendingGovernanceUpdated(_pendingGovernance);
  }

  function acceptGovernance() external {
    require(msg.sender == pendingGovernance, "StakingPools: only pending governance");

    address _pendingGovernance = pendingGovernance;
    governance = _pendingGovernance;

    emit GovernanceUpdated(_pendingGovernance);
  }

  /// @dev Sets the distribution reward rate.
  ///
  /// This will update all of the pools.
  ///
  /// @param _rewardRate The number of tokens to distribute per block.
  function setRewardRate(uint256 _rewardRate) external onlyGovernance {
    _updatePools();

    _ctx.rewardRate = _rewardRate;

    emit RewardRateUpdated(_rewardRate);
  }

  /// @dev Creates a new pool.
  ///
  /// The created pool will need to have its reward weight initialized before it begins generating rewards.
  ///
  /// @param _token The token the pool will accept for staking.
  ///
  /// @return the identifier for the newly created pool.
  function createPool(IERC20 _token) external onlyGovernance returns (uint256) {
    require(tokenPoolIds[_token] == 0, "StakingPools: token already has a pool");

    uint256 _poolId = _pools.length();

    _pools.push(Pool.Data({
      token: _token,
      totalDeposited: 0,
      rewardWeight: 0,
      accumulatedRewardWeight: FixedPointMath.uq192x64(0),
      lastUpdatedBlock: block.number,
      escrowPercentage: 0,
      exitFeePercentage: 0
    }));

    tokenPoolIds[_token] = _poolId + 1;

    emit PoolCreated(_poolId, _token);

    return _poolId;
  }

  /// @dev Sets the reward weights of all of the pools.
  ///
  /// @param _rewardWeights The reward weights of all of the pools.
  function setRewardWeights(uint256[] calldata _rewardWeights) external onlyGovernance {
    require(_rewardWeights.length == _pools.length(), "StakingPools: weights length mismatch");

    _updatePools();

    uint256 _totalRewardWeight = _ctx.totalRewardWeight;
    for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
      Pool.Data storage _pool = _pools.get(_poolId);

      uint256 _currentRewardWeight = _pool.rewardWeight;
      if (_currentRewardWeight == _rewardWeights[_poolId]) {
        continue;
      }

      // FIXME
      _totalRewardWeight = _totalRewardWeight.sub(_currentRewardWeight).add(_rewardWeights[_poolId]);
      _pool.rewardWeight = _rewardWeights[_poolId];

      emit PoolRewardWeightUpdated(_poolId, _rewardWeights[_poolId]);
    }

    _ctx.totalRewardWeight = _totalRewardWeight;
  }

  /// @dev Sets the escrow percentages of all the pools
  ///
  /// @param _escrowPercentages Escrow percentages 1e18 == 100%
  function setEscrowPercentages(uint256[] calldata _escrowPercentages) external onlyGovernance {
      require(_escrowPercentages.length == _pools.length(), "StakingPools: escrow percentages length mismatch");

      _updatePools();

      for(uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
        Pool.Data storage _pool =  _pools.get(_poolId);

        require(_escrowPercentages[_poolId] <= 1 ether, "StakingPools: escrow percentage should be 100% max");

        uint256 _currentEscrowPercentage = _pool.escrowPercentage;
        if(_currentEscrowPercentage == _escrowPercentages[_poolId]) {
            continue;
        }

        _pool.escrowPercentage = _escrowPercentages[_poolId];
        emit PoolEscrowPercentageUpdated(_poolId, _escrowPercentages[_poolId]);
      }
  }

  /// @dev Sets the exit fees of all the pools
  ///
  /// @param _exitFeePercentages Exit fee percentages. 10% == 1e17
  function setExitFeePercentages(uint256[] calldata _exitFeePercentages) external onlyGovernance {
      require(_exitFeePercentages.length == _pools.length(), "StakingPools: exit fee percentages length mismatch");

      _updatePools();

      for(uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
        Pool.Data storage _pool =  _pools.get(_poolId);

        require(_exitFeePercentages[_poolId] <= 1 ether, "StakingPools: exit fee percentage should be 100% max");

        uint256 _currentExitFeePercentage = _pool.exitFeePercentage;
        if(_currentExitFeePercentage == _exitFeePercentages[_poolId]) {
            continue;
        }

        _pool.exitFeePercentage = _exitFeePercentages[_poolId];
        emit PoolExitFeePercentageUpdated(_poolId, _exitFeePercentages[_poolId]);
      }
  }

  /// @dev Set the exit fee receiver
  ///
  /// @param _exitFeeReceiver Address that will receive the exit fees
  function setExitFeeReceiver(address _exitFeeReceiver) external onlyGovernance {
    require(_exitFeeReceiver != address(0), "StakingPools: exit fee receiver address cannot be 0x0");
    exitFeeReceiver = _exitFeeReceiver;
    emit ExitFeeReceiverUpdated(_exitFeeReceiver);
  }


  /// @dev Set refferer values
  ///
  /// @param _referrer Address of the referrer
  /// @param _referralPercentage ReferralPercentage
  /// @param _referralEscrowPercentage Amount of rewards that get escrowed
  function setReferrerValues(address _referrer, uint256 _referralPercentage, uint256 _referralEscrowPercentage) external onlyGovernance {
    referralPercentageOf[_referrer] = _referralPercentage;
    referralEscrowPercentageOf[_referrer] = _referralEscrowPercentage;
  }

  /// @dev Stakes tokens into a pool.
  ///
  /// @param _poolId        the pool to deposit tokens into.
  /// @param _depositAmount the amount of tokens to deposit.
  function deposit(uint256 _poolId, uint256 _depositAmount) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    _deposit(_poolId, _depositAmount);
  }

  /// @dev Stakes tokens into a pool.
  ///
  /// @param _poolId        the pool to deposit tokens into.
  /// @param _depositAmount the amount of tokens to deposit.
  function depositReferred(uint256 _poolId, uint256 _depositAmount, address _referrer) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    // set referrer if not already set
    if(referrerOf[msg.sender] == address(0)) {
      referrerOf[msg.sender] = _referrer;
      emit ReferrerSet(msg.sender, _referrer);
    }

    _deposit(_poolId, _depositAmount);
  }

  /// @dev Withdraws staked tokens from a pool.
  ///
  /// @param _poolId          The pool to withdraw staked tokens from.
  /// @param _withdrawAmount  The number of tokens to withdraw.
  function withdraw(uint256 _poolId, uint256 _withdrawAmount) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);
    
    _claim(_poolId);
    _withdraw(_poolId, _withdrawAmount);
  }

  /// @dev Claims all rewarded tokens from a pool.
  ///
  /// @param _poolId The pool to claim rewards from.
  ///
  /// @notice use this function to claim the tokens from a corresponding pool by ID.
  function claim(uint256 _poolId) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    _claim(_poolId);
  }

  /// @dev Claim referral rewards
  function claimReferralRewards() external nonReentrant {
    uint256 _amount = referrerBalanceOf[msg.sender];
    referrerBalanceOf[msg.sender] = 0;

    uint256 _escrowedAmount = _amount.mul(referralEscrowPercentageOf[msg.sender]).div(1e18);

    if(_escrowedAmount != 0) {
        // escrow
        reward.safeTransferFrom(rewardSource, address(rewardEscrow), _escrowedAmount);
        rewardEscrow.appendVestingEntry(msg.sender, _escrowedAmount);
    }

     uint256 _nonEscrowedAmount = _amount.sub(_escrowedAmount);

    if(_nonEscrowedAmount != 0) {
      reward.safeTransferFrom(rewardSource, msg.sender, _nonEscrowedAmount);
    }
  }

  /// @dev Withdraws staked tokens leaving the rewards. Only to be used in case of emergency
  ///
  /// @param _poolId the pool to exit from
  function emergencyExit(uint256 _poolId) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    _withdraw(_poolId, _stake.totalDeposited);
  }

  /// @dev Claims all rewards from a pool and then withdraws all staked tokens.
  ///
  /// @param _poolId the pool to exit from.
  function exit(uint256 _poolId) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    _claim(_poolId);
    _withdraw(_poolId, _stake.totalDeposited);
  }

  /// @dev Gets the rate at which tokens are minted to stakers for all pools.
  ///
  /// @return the reward rate.
  function rewardRate() external view returns (uint256) {
    return _ctx.rewardRate;
  }

  /// @dev Gets the total reward weight between all the pools.
  ///
  /// @return the total reward weight.
  function totalRewardWeight() external view returns (uint256) {
    return _ctx.totalRewardWeight;
  }

  /// @dev Gets the number of pools that exist.
  ///
  /// @return the pool count.
  function poolCount() external view returns (uint256) {
    return _pools.length();
  }

  /// @dev Gets the token a pool accepts.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the token.
  function getPoolToken(uint256 _poolId) external view returns (IERC20) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.token;
  }

  /// @dev Gets the total amount of funds staked in a pool.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the total amount of staked or deposited tokens.
  function getPoolTotalDeposited(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.totalDeposited;
  }

  /// @dev Gets the reward weight of a pool which determines how much of the total rewards it receives per block.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool reward weight.
  function getPoolRewardWeight(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.rewardWeight;
  }

  /// @dev Gets the escrow percentage of a pool which determines how much of the reward is escrowed
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool escrow percentage
  function getPoolEscrowPercentage(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.escrowPercentage;
  }

  /// @dev Gets the exit fee percentage of a pool which determines how much of a withdraw penalty is charged
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool exit fee percentage
  function getPoolExitFeePercentage(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.exitFeePercentage;
  }

  /// @dev Gets the amount of tokens per block being distributed to stakers for a pool.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool reward rate.
  function getPoolRewardRate(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.getRewardRate(_ctx);
  }

  /// @dev Get all pools and info
  ///
  /// @param _account address of the specific
  ///
  /// @return pools info
  function getPools(address _account) external view returns (Pool.ViewData[] memory) {
    Pool.ViewData[] memory _data = new Pool.ViewData[](_pools.length());

    for(uint256 i = 0; i < _pools.length(); i++) {
      Pool.Data storage _pool = _pools.get(i);
      Stake.Data storage _stake = _stakes[_account][i];

      _data[i] = Pool.ViewData({
        token: _pool.token,
        totalDeposited: _pool.totalDeposited,
        rewardWeight: _pool.rewardWeight,
        accumulatedRewardWeight: _pool.accumulatedRewardWeight,
        lastUpdatedBlock: _pool.lastUpdatedBlock,
        escrowPercentage: _pool.escrowPercentage,
        exitFeePercentage: _pool.exitFeePercentage,
        rewardRate: _pool.getRewardRate(_ctx),
        userDeposited: _stake.totalDeposited,
        userUnclaimed: _stake.getUpdatedTotalUnclaimed(_pool, _ctx),
        userTokenBalance: _pool.token.balanceOf(_account),
        userTokenApproval: _pool.token.allowance(_account, address(this))
      });
    }

    return _data; 
  }

  /// @dev Gets the number of tokens a user has staked into a pool.
  ///
  /// @param _account The account to query.
  /// @param _poolId  the identifier of the pool.
  ///
  /// @return the amount of deposited tokens.
  function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256) {
    Stake.Data storage _stake = _stakes[_account][_poolId];
    return _stake.totalDeposited;
  }

  /// @dev Gets the number of unclaimed reward tokens a user can claim from a pool.
  ///
  /// @param _account The account to get the unclaimed balance of.
  /// @param _poolId  The pool to check for unclaimed rewards.
  ///
  /// @return the amount of unclaimed reward tokens a user has in a pool.
  function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256) {
    Stake.Data storage _stake = _stakes[_account][_poolId];
    return _stake.getUpdatedTotalUnclaimed(_pools.get(_poolId), _ctx);
  }

  /// @dev Updates all of the pools.
  function _updatePools() internal {
    for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
      Pool.Data storage _pool = _pools.get(_poolId);
      _pool.update(_ctx);
    }
  }

  /// @dev Stakes tokens into a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId        the pool to deposit tokens into.
  /// @param _depositAmount the amount of tokens to deposit.
  function _deposit(uint256 _poolId, uint256 _depositAmount) internal {
    Pool.Data storage _pool = _pools.get(_poolId);
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    _pool.totalDeposited = _pool.totalDeposited.add(_depositAmount);
    _stake.totalDeposited = _stake.totalDeposited.add(_depositAmount);

    _pool.token.safeTransferFrom(msg.sender, address(this), _depositAmount);

    emit TokensDeposited(msg.sender, _poolId, _depositAmount);
  }

  /// @dev Withdraws staked tokens from a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId          The pool to withdraw staked tokens from.
  /// @param _withdrawAmount  The number of tokens to withdraw.
  function _withdraw(uint256 _poolId, uint256 _withdrawAmount) internal {
    Pool.Data storage _pool = _pools.get(_poolId);
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    _pool.totalDeposited = _pool.totalDeposited.sub(_withdrawAmount);
    _stake.totalDeposited = _stake.totalDeposited.sub(_withdrawAmount);

    uint256 _exitFeeAmount = _withdrawAmount.mul(_pool.exitFeePercentage).div(1e18);
    if(_exitFeeAmount > 0) {
      _pool.token.safeTransfer(exitFeeReceiver, _exitFeeAmount);
    }

    uint256 _withdrawAmountSansFee = _withdrawAmount.sub(_exitFeeAmount);
    if(_withdrawAmountSansFee > 0) {
      _pool.token.safeTransfer(msg.sender, _withdrawAmountSansFee);
    }

    emit TokensWithdrawn(msg.sender, _poolId, _withdrawAmount);
  }

  /// @dev Claims all rewarded tokens from a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId The pool to claim rewards from.
  ///
  /// @notice use this function to claim the tokens from a corresponding pool by ID.
  function _claim(uint256 _poolId) internal {
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    Pool.Data storage _pool = _pools.get(_poolId);

    uint256 _claimAmount = _stake.totalUnclaimed;
    _stake.totalUnclaimed = 0;

    uint256 _escrowedAmount = _claimAmount.mul(_pool.escrowPercentage).div(1e18);

    if(_escrowedAmount != 0) {
        // escrow
        reward.safeTransferFrom(rewardSource, address(rewardEscrow), _escrowedAmount);
        rewardEscrow.appendVestingEntry(msg.sender, _escrowedAmount);
    }

    uint256 _nonEscrowedAmount = _claimAmount.sub(_escrowedAmount);

    if(_nonEscrowedAmount != 0) {
      reward.safeTransferFrom(rewardSource, msg.sender, _nonEscrowedAmount);
    }

    address _referrer = referrerOf[msg.sender];

    if(_referrer != address(0)) {
      uint256 _referralAmount = _claimAmount.mul(referralPercentageOf[_referrer]).div(1e18);
      referrerBalanceOf[_referrer] = referrerBalanceOf[_referrer].add(_referralAmount);
      emit ReferrerPaid(msg.sender, _referrer, _referralAmount);
    }

    emit TokensClaimed(msg.sender, _poolId, _claimAmount);
  }

  function saveToken(address _token, address _to, uint256 _amount) external onlyGovernance {
    IERC20(_token).transfer(_to, _amount);
  }
  
  function saveEth(address payable _to, uint256 _amount) external onlyGovernance {
    _to.call{value: _amount}("");
  }
}