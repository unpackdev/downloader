// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IBasePool.sol";
import "./TokenSaver.sol";

contract StakingPoolManager is TokenSaver {
  using SafeERC20 for IERC20;

  bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
  bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");
  uint256 public constant MAX_POOL_COUNT = 10;

  IERC20 public immutable reward;
  address public immutable rewardSource;
  /// @dev RewardPerBlock
  uint256 public rewardPerBlock;
  /// @dev When rewards were last paid
  uint256 public lastRewardBlock;
  /// @dev Reward end block
  uint256 public rewardEndBlock;
  uint256 public totalWeight;

  mapping(address => bool) public poolAdded;
  Pool[] public pools;

  struct Pool {
    IBasePool poolContract;
    uint256 weight;
  }

  modifier onlyGov() {
    require(hasRole(GOV_ROLE, _msgSender()), "only gov");
    _;
  }

  modifier onlyRewardDistributor() {
    require(hasRole(REWARD_DISTRIBUTOR_ROLE, _msgSender()), "only reward dist");
    _;
  }

  event PoolAdded(address indexed pool, uint256 weight);
  event PoolRemoved(uint256 indexed poolId, address indexed pool);
  event WeightAdjusted(uint256 indexed poolId, address indexed pool, uint256 newWeight);
  event SetRewardsPerBlock(uint256 rewardsPerBlock);
  event SetRewardEndBlock(uint256 rewardEndBlock);
  event RewardsDistributed(address _from, uint256 indexed _amount);

  constructor(
    address _reward,
    address _rewardSource,
    uint256 _rewardStartBlock,
    uint256 _rewardEndBlock
  ) {
    require(_reward != address(0), "bad _reward");
    require(_rewardSource != address(0), "bad _rewardSource");
    require(_rewardStartBlock > block.number && _rewardStartBlock < _rewardEndBlock, "bad _rewardStartBlock");
    reward = IERC20(_reward);
    rewardSource = _rewardSource;
    lastRewardBlock = _rewardStartBlock;
    rewardEndBlock = _rewardEndBlock;
  }

  function addPool(address _poolContract, uint256 _weight) external onlyGov {
    _distributeRewards();
    require(_poolContract != address(0), "bad _poolContract");
    require(!poolAdded[_poolContract], "pool already added");
    require(pools.length < MAX_POOL_COUNT, "max amount of pools reached");
    // add pool
    pools.push(Pool({ poolContract: IBasePool(_poolContract), weight: _weight }));
    poolAdded[_poolContract] = true;

    // increase totalWeight
    totalWeight += _weight;

    // Approve max token amount
    reward.safeApprove(_poolContract, type(uint256).max);

    emit PoolAdded(_poolContract, _weight);
  }

  function removePool(uint256 _poolId) external onlyGov {
    require(_poolId < pools.length, "!exist");
    _distributeRewards();
    address poolAddress = address(pools[_poolId].poolContract);

    // decrease totalWeight
    totalWeight -= pools[_poolId].weight;

    // remove pool
    pools[_poolId] = pools[pools.length - 1];
    pools.pop();
    poolAdded[poolAddress] = false;

    emit PoolRemoved(_poolId, poolAddress);
  }

  function adjustWeight(uint256 _poolId, uint256 _newWeight) external onlyGov {
    require(_poolId < pools.length, "!exist");
    _distributeRewards();
    Pool storage pool = pools[_poolId];

    totalWeight -= pool.weight;
    totalWeight += _newWeight;

    pool.weight = _newWeight;

    emit WeightAdjusted(_poolId, address(pool.poolContract), _newWeight);
  }

  function setRewardEndBlock(uint256 _rewardEndBlock) external onlyGov {
    require(_rewardEndBlock > rewardEndBlock, "!future");
    rewardEndBlock = _rewardEndBlock;
    emit SetRewardEndBlock(rewardPerBlock);
  }

  function setRewardPerBlock(uint256 _rewardPerBlock) external onlyGov {
    _distributeRewards();
    rewardPerBlock = _rewardPerBlock;
    emit SetRewardsPerBlock(_rewardPerBlock);
  }

  /// @notice Return reward multiplier over the given _from to _to block.
  function getMultiplier(
    uint256 _from,
    uint256 _to,
    uint256 _endBlock
  ) public pure returns (uint256) {
    if ((_from >= _endBlock) || (_from > _to)) {
      return 0;
    }
    if (_to <= _endBlock) {
      return _to - _from;
    }
    return _endBlock - _from;
  }

  function _distributeRewards() internal {
    uint256 blockPassed = getMultiplier(lastRewardBlock, block.number, rewardEndBlock);

    if (blockPassed == 0) {
      return;
    }

    uint256 totalRewardAmount = rewardPerBlock * blockPassed;
    lastRewardBlock = block.number >= rewardEndBlock ? rewardEndBlock : block.number;

    // return if pool length == 0
    if (pools.length == 0) {
      return;
    }

    // return if accrued rewards == 0
    if (totalRewardAmount == 0) {
      return;
    }

    reward.safeTransferFrom(rewardSource, address(this), totalRewardAmount);

    for (uint256 i = 0; i < pools.length; i++) {
      Pool memory pool = pools[i];
      uint256 poolRewardAmount = (totalRewardAmount * pool.weight) / totalWeight;
      // Ignore tx failing to prevent a single pool from halting reward distribution
      // solhint-disable-next-line
      address(pool.poolContract).call(
        abi.encodeWithSelector(pool.poolContract.distributeRewards.selector, poolRewardAmount)
      );
    }

    uint256 leftOverReward = reward.balanceOf(address(this));

    // send back excess but ignore dust
    if (leftOverReward > 1) {
      reward.safeTransfer(rewardSource, leftOverReward);
    }

    emit RewardsDistributed(_msgSender(), totalRewardAmount);
  }

  function distributeRewards() external onlyRewardDistributor {
    _distributeRewards();
  }

  function getPools() external view returns (Pool[] memory result) {
    return pools;
  }
}
