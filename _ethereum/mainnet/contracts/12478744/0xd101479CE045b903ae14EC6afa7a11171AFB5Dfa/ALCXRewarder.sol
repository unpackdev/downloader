// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";

import "./BoringMath.sol";
import "./BoringOwnable.sol";
import "./BoringERC20.sol";

import "./IRewarder.sol";
import "./IMasterChefV2.sol";

import "./console.sol";

contract ALCXRewarder is IRewarder, BoringOwnable {
	using BoringMath for uint256;
	using BoringMath128 for uint128;
	using BoringERC20 for IERC20;

	IERC20 private immutable rewardToken;
	IMasterChefV2 private immutable MC_V2;

	/// @notice Info of each MCV2 user.
	/// `amount` LP token amount the user has provided.
	/// `rewardDebt` The amount of SUSHI entitled to the user.
	struct UserInfo {
		uint256 amount;
		uint256 rewardDebt;
	}

	/// @notice Info of each MCV2 pool.
	/// `allocPoint` The amount of allocation points assigned to the pool.
	/// Also known as the amount of SUSHI to distribute per block.
	struct PoolInfo {
		uint128 accTokenPerShare;
		uint64 lastRewardBlock;
		uint64 allocPoint;
	}

	uint256[] public poolIds;
	/// @notice Info of each pool.
	mapping(uint256 => PoolInfo) public poolInfo;
	/// @notice Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	/// @dev Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 totalAllocPoint;

	uint256 public tokenPerBlock;
	uint256 private constant ACC_TOKEN_PRECISION = 1e12;

	event PoolAdded(uint256 indexed pid, uint256 allocPoint);
	event PoolSet(uint256 indexed pid, uint256 allocPoint);
	event PoolUpdated(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accTokenPerShare);
	event OnReward(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event RewardRateUpdated(uint256 oldRate, uint256 newRate);

	modifier onlyMCV2 {
		require(msg.sender == address(MC_V2), "ALCXRewarder::onlyMCV2: only MasterChef V2 can call this function.");
		_;
	}

	constructor(
		IERC20 _rewardToken,
		uint256 _tokenPerBlock,
		IMasterChefV2 _MCV2
	) public {
		require(Address.isContract(address(_rewardToken)), "ALCXRewarder: reward token must be a valid contract");
		require(Address.isContract(address(_MCV2)), "ALCXRewarder: MasterChef V2 must be a valid contract");

		rewardToken = _rewardToken;
		tokenPerBlock = _tokenPerBlock;
		MC_V2 = _MCV2;
	}

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	/// @param allocPoint AP of the new pool.
	/// @param _pid Pid on MCV2
	function addPool(uint256 _pid, uint256 allocPoint) public onlyOwner {
		require(poolInfo[_pid].lastRewardBlock == 0, "ALCXRewarder::add: cannot add existing pool");

		uint256 lastRewardBlock = block.number;
		totalAllocPoint = totalAllocPoint.add(allocPoint);

		poolInfo[_pid] = PoolInfo({
			allocPoint: allocPoint.to64(),
			lastRewardBlock: lastRewardBlock.to64(),
			accTokenPerShare: 0
		});
		poolIds.push(_pid);

		emit PoolAdded(_pid, allocPoint);
	}

	/// @notice Update the given pool's SUSHI allocation point and `IRewarder` contract. Can only be called by the owner.
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _allocPoint New AP of the pool.
	function setPool(uint256 _pid, uint256 _allocPoint) public onlyOwner {
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint.to64();

		emit PoolSet(_pid, _allocPoint);
	}

	/// @notice Update reward variables of the given pool.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @return pool Returns the pool that was updated.
	function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
		pool = poolInfo[pid];

		if (block.number > pool.lastRewardBlock) {
			uint256 lpSupply = MC_V2.lpToken(pid).balanceOf(address(MC_V2));

			if (lpSupply > 0) {
				uint256 blocks = block.number.sub(pool.lastRewardBlock);
				uint256 tokenReward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
				pool.accTokenPerShare = pool.accTokenPerShare.add(
					(tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128()
				);
			}

			pool.lastRewardBlock = block.number.to64();
			poolInfo[pid] = pool;

			emit PoolUpdated(pid, pool.lastRewardBlock, lpSupply, pool.accTokenPerShare);
		}
	}

	/// @notice Update reward variables for all pools
	/// @dev Be careful of gas spending!
	/// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
	function massUpdatePools(uint256[] calldata pids) public {
		uint256 len = pids.length;
		for (uint256 i = 0; i < len; ++i) {
			updatePool(pids[i]);
		}
	}

	/// @dev Sets the distribution reward rate. This will also update all of the pools.
	/// @param _tokenPerBlock The number of tokens to distribute per block
	function setRewardRate(uint256 _tokenPerBlock, uint256[] calldata _pids) external onlyOwner {
		massUpdatePools(_pids);

		uint256 oldRate = tokenPerBlock;
		tokenPerBlock = _tokenPerBlock;

		emit RewardRateUpdated(oldRate, _tokenPerBlock);
	}

	function onSushiReward(
		uint256 pid,
		address _user,
		address to,
		uint256,
		uint256 lpToken
	) external override onlyMCV2 {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][_user];
		uint256 pending;
		// if user had deposited
		if (user.amount > 0) {
			pending = (user.amount.mul(pool.accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
			rewardToken.safeTransfer(to, pending);
		}

		user.amount = lpToken;
		user.rewardDebt = user.rewardDebt.add(pending);

		emit OnReward(_user, pid, pending, to);
	}

	function pendingTokens(
		uint256 pid,
		address user,
		uint256
	) external view override returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
		IERC20[] memory _rewardTokens = new IERC20[](1);
		_rewardTokens[0] = (rewardToken);

		uint256[] memory _rewardAmounts = new uint256[](1);
		_rewardAmounts[0] = pendingToken(pid, user);

		return (_rewardTokens, _rewardAmounts);
	}

	/// @notice View function to see pending Token
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _user Address of user.
	/// @return pending SUSHI reward for a given user.
	function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
		PoolInfo memory pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];

		uint256 accTokenPerShare = pool.accTokenPerShare;
		uint256 lpSupply = MC_V2.lpToken(_pid).balanceOf(address(MC_V2));

		if (block.number > pool.lastRewardBlock && lpSupply != 0) {
			uint256 blocks = block.number.sub(pool.lastRewardBlock);
			uint256 tokenReward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
			accTokenPerShare = accTokenPerShare.add(tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply);
		}

		pending = (user.amount.mul(accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
	}
}
