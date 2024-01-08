// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./zStakePoolBase.sol";

/**
 * @title Wild Core Pool - Fork of Illuvium Core Pool
 *
 * @notice Core pools represent permanent pools like WILD or WILD/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See WildPoolBase for more details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin, modified by Zer0
 */
contract zStakeCorePool is zStakePoolBase {
  /// @dev Flag indicating pool type, false means "core pool"
  bool public constant override isFlashPool = false;

  /// @dev Pool tokens value available in the pool;
  ///      pool token examples are WILD (WILD core pool) or WILD/ETH pair (LP core pool)
  /// @dev For LP core pool this value doesnt' count for WILD tokens received as Vault rewards
  ///      while for WILD core pool it does count for such tokens as well
  uint256 public poolTokenReserve;

  /**
   * @dev Creates/deploys an instance of the core pool
   *
   * @param _rewardToken WILD ERC20 Token address
   * @param _factory Pool factory zStakePoolFactory instance/address
   * @param _poolToken token the pool operates on, for example WILD or WILD/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   */
  function initialize(
    address _rewardToken,
    zStakePoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) initializer public {
    __zStakePoolBase__init(_rewardToken, _factory, _poolToken, _initBlock, _weight);
  }

  // Call this on the implementation contract (not the proxy)
  function initializeImplementation() public initializer {
    __Ownable_init();
    _pause();
  }

  /**
   * @notice Service function to calculate and pay pending vault and yield rewards to the sender
   *
   * @dev Internally executes similar function `_processRewards` from the parent smart contract
   *      to calculate and pay yield rewards; adds vault rewards processing
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   */
  function processRewards() external override {
    require(!paused(), "contract is paused");
    _processRewards(msg.sender, true);
  }

  /**
   * @dev Executed internally by the pool itself (from the parent `zStakePoolBase` smart contract)
   *      as part of yield rewards processing logic (`zStakePoolBase._processRewards` function)
   *
   * @param _staker an address which stakes (the yield reward)
   * @param _amount amount to be staked (yield reward amount)
   */
  function stakeAsPool(address _staker, uint256 _amount) external {
    require(!paused(), "contract is paused");
    require(factory.poolExists(msg.sender), "access denied");
    _sync();
    User storage user = users[_staker];
    if (user.tokenAmount > 0) {
      _processRewards(_staker, false);
    }
    uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
    Deposit memory newDeposit = Deposit({
      tokenAmount: _amount,
      lockedFrom: uint64(now256()),
      lockedUntil: uint64(now256() + rewardLockPeriod),
      weight: depositWeight,
      isYield: true
    });
    user.tokenAmount += _amount;
    user.totalWeight += depositWeight;
    user.deposits.push(newDeposit);

    usersLockingWeight += depositWeight;

    user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

    // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc zStakePoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockedUntil,
    bool _isYield
  ) internal override {
    super._stake(_staker, _amount, _lockedUntil, _isYield);

    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc zStakePoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount
  ) internal override {
    User storage user = users[_staker];
    Deposit memory stakeDeposit = user.deposits[_depositId];
    require(
      stakeDeposit.lockedFrom == 0 || now256() > stakeDeposit.lockedUntil,
      "deposit not yet unlocked"
    );
    poolTokenReserve -= _amount;
    super._unstake(_staker, _depositId, _amount);
  }

  /**
   * @inheritdoc zStakePoolBase
   *
   * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
   *      and for reward pool pool updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _processRewards(address _staker, bool _withUpdate)
    internal
    override
    returns (uint256 pendingYield)
  {
    pendingYield = super._processRewards(_staker, _withUpdate);

    // update `poolTokenReserve` only if this is the reward Pool
    if (poolToken == rewardToken) {
      poolTokenReserve += pendingYield;
    }
  }
}
