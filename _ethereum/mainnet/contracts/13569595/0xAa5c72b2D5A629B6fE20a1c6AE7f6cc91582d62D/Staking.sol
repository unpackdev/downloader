// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ITokenaFactory.sol";
import "./IStaking.sol";

/**
 * @title A master staking contact
 * @dev Will be deployed once as master contact
 */
contract Staking is IStaking, AccessControl, ReentrancyGuard {
	using SafeERC20 for ERC20;

	ITokenaFactory public immutable factory;

	// Whether it is initialized and
	bool private _isInitialized;
	uint8 public bonusMultiplier;

	// Accrued token per share
	uint256[] public accTokenPerShare;

	uint256 public stakers;
	uint256 public startBlock;
	uint256 public endBlock;
	uint256 public bonusStartBlock;
	uint256 public bonusEndBlock;
	uint256[] public rewardPerBlock;
	uint256[] public rewardTokenAmounts;
	uint256 public stakedTokenSupply;
	// The precision factor

	// The reward token
	ERC20[] public rewardToken;
	// The staked token
	ERC20 public stakedToken;
	ProjectInfo public info;

	uint128[] private _PRECISION_FACTOR;
	uint256 private _numOfRewardTokens;
	uint256 private _lastRewardBlock;

	// Info of each user that stakes tokens (stakedToken)
	mapping(address => UserInfo) public userInfo;

	struct UserInfo {
		uint256 amount; // How many staked tokens the user has provided
		uint256[] rewardDebt; // Reward debt
	}

	constructor(address adr) {
		factory = ITokenaFactory(adr);
	}

	/**
	 * @notice initialize stake/LM for user
	 * @param _stakedToken: address of staked token
	 * @param _rewardToken: address of reward token
	 * @param _rewardTokenAmounts: amount of tokens for reward
	 * @param _startBlock: start time in blocks
	 * @param _endBlock: estimate time of life for pool in blocks
	 * @param admin: address of user owner
	 */
	function initialize(
		address _stakedToken,
		address[] calldata _rewardToken,
		uint256[] calldata _rewardTokenAmounts,
		uint256 _startBlock,
		uint256 _endBlock,
		ProjectInfo calldata _info,
		address admin
	) external override {
		require(!_isInitialized, "Already initialized");
		require(msg.sender == address(factory), "Initialize not from factory");
		_isInitialized = true;
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		// Make this contract initialized
		stakedToken = ERC20(_stakedToken);
		uint256 i;
		for (i; i < _rewardToken.length; i++) {
			rewardToken.push(ERC20(_rewardToken[i]));
			accTokenPerShare.push(0);

			rewardPerBlock.push(_rewardTokenAmounts[i] / (_endBlock - _startBlock));

			uint8 decimalsRewardToken = (ERC20(_rewardToken[i]).decimals());
			require(decimalsRewardToken < 30, "Must be inferior to 30");
			_PRECISION_FACTOR.push(uint128(10**(30 - (decimalsRewardToken))));
		}
		info = _info;
		startBlock = _startBlock;
		_lastRewardBlock = _startBlock;
		bonusMultiplier = 1;
		endBlock = _endBlock;
		rewardTokenAmounts = _rewardTokenAmounts;
		_numOfRewardTokens = _rewardToken.length;
	}

	/**
	 * @notice Deposit staked tokens and collect reward tokens (if any)
	 * @param amount: amount to deposit (in stakedToken)
	 */
	function deposit(uint256 amount) external nonReentrant {
		require(amount != 0, "Must deposit not 0");
		require(block.number < endBlock, "Pool already end");
		UserInfo storage user = userInfo[msg.sender];
		uint256 pending;
		uint256 i;
		if (user.rewardDebt.length == 0) {
			user.rewardDebt = new uint256[](_numOfRewardTokens);
			stakers++;
		}
		_updatePool();
		uint256 curAmount = user.amount;
		uint256 balanceBefore = stakedToken.balanceOf(address(this));
		stakedToken.safeTransferFrom(address(msg.sender), address(this), amount);
		uint256 balanceAfter = stakedToken.balanceOf(address(this));
		user.amount = user.amount + (balanceAfter - balanceBefore);
		stakedTokenSupply += (balanceAfter - balanceBefore);

		for (i = 0; i < _numOfRewardTokens; i++) {
			if (curAmount > 0) {
				pending = (curAmount * (accTokenPerShare[i])) / (_PRECISION_FACTOR[i]) - (user.rewardDebt[i]);

				if (pending > 0) {
					rewardToken[i].safeTransfer(address(msg.sender), pending);
				}
			}
			user.rewardDebt[i] = (user.amount * (accTokenPerShare[i])) / (_PRECISION_FACTOR[i]);
		}
	}

	/**
	 * @notice Withdraw staked tokens and collect reward tokens
	 * @param amount: amount to withdraw (in stakedToken)
	 */
	function withdraw(uint256 amount) external nonReentrant {
		UserInfo storage user = userInfo[msg.sender];
		require(user.amount >= amount, "Amount to withdraw too high");
		bool flag;
		_updatePool();

		uint256 pending;
		uint256 i;
		uint256 curAmount = user.amount;
		if (amount > 0) {
			user.amount = user.amount - (amount);
			stakedToken.safeTransfer(address(msg.sender), amount);
			if (user.amount == 0) {
				flag = true;
			}
		}
		stakedTokenSupply -= amount;
		for (i = 0; i < _numOfRewardTokens; i++) {
			pending = ((curAmount * (accTokenPerShare[i])) / (_PRECISION_FACTOR[i]) - (user.rewardDebt[i]));
			if (pending > 0) {
				rewardToken[i].safeTransfer(address(msg.sender), pending);
			}

			user.rewardDebt[i] = (user.amount * (accTokenPerShare[i])) / (_PRECISION_FACTOR[i]);
		}

		if (flag) {
			delete (userInfo[msg.sender]);
			stakers--;
		}
	}

	/**
	 * @notice Collect reward tokens of a certain index
	 * @param index: index of the reward token
	 */
	function withdrawOnlyIndexWithoutUnstake(uint256 index) external nonReentrant {
		require(index < _numOfRewardTokens, "Wrong index");
		UserInfo storage user = userInfo[msg.sender];

		_updatePool();

		uint256 newRewardDebt = ((user.amount * (accTokenPerShare[index])) / (_PRECISION_FACTOR[index]));

		uint256 pending = (newRewardDebt - (user.rewardDebt[index]));

		if (pending > 0) {
			rewardToken[index].safeTransfer(address(msg.sender), pending);
		}

		user.rewardDebt[index] = newRewardDebt;
	}

	/**
	 * @notice Withdraw staked tokens without caring about rewards rewards
	 * @dev Needs to be for emergency.
	 */
	function emergencyWithdraw() external nonReentrant {
		UserInfo storage user = userInfo[msg.sender];
		uint256 amountToTransfer = user.amount;
		stakedTokenSupply -= amountToTransfer;
		delete (userInfo[msg.sender]);
		stakers--;
		if (amountToTransfer > 0) {
			stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
		}
	}

	/**
	 * @notice Update project info
	 * @param _info Struct of name, link, themeId
	 */
	function updateProjectInfo(ProjectInfo calldata _info) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(bytes(info.name).length != 0, "Must set name");
		require(info.themeId > 0 && info.themeId < 10, "Wrong theme id");
		info = _info;
	}

	/**
	 * @notice Collect all reward tokens left in pool after certain time has passed
	 * @param toTransfer: address to transfer leftover tokens to
	 */
	function getLeftovers(address toTransfer) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
		require((endBlock + factory.getDelta()) >= block.number, "Too early");
		for (uint256 i; i < _numOfRewardTokens; i++) {
			ERC20 token = rewardToken[i];
			token.safeTransfer(toTransfer, token.balanceOf(address(this)));
		}
	}

	/**
	 * @notice Start bonus time
	 * @param _bonusMultiplier multiplier reward
	 * @param _bonusStartBlock block from which bonus starts
	 * @param _bonusEndBlock block in which user want stop bonus period
	 */
	function startBonusTime(
		uint8 _bonusMultiplier,
		uint256 _bonusStartBlock,
		uint256 _bonusEndBlock
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_bonusMultiplier > 1, "Multiplier must be > 1");
		require(_bonusStartBlock >= startBlock && _bonusStartBlock < endBlock, "Non valid start time");
		require(_bonusEndBlock > startBlock && _bonusEndBlock > _bonusStartBlock, "Non valid end time");
		_updatePool();
		require(bonusEndBlock == 0, "Can't start another Bonus Time");
		uint256 _endBlock = endBlock - ((_bonusEndBlock - _bonusStartBlock) * (_bonusMultiplier - 1));
		require(_endBlock > block.number && _endBlock > startBlock, "Not enough rewards for Bonus");
		if (_endBlock < _bonusEndBlock) {
			bonusEndBlock = _endBlock;
		} else {
			bonusEndBlock = _bonusEndBlock;
		}
		bonusMultiplier = _bonusMultiplier;
		bonusStartBlock = _bonusStartBlock;
		endBlock = _endBlock;
	}

	/**
	 * @notice Change time of end pool
	 * @param _endBlock endBlock
	 */
	function updateEndBlock(uint256 _endBlock) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
		require(endBlock > block.number, "Pool already finished");
		require(_endBlock > endBlock, "Cannot shorten");
		uint256 blocksAdded = _endBlock - endBlock;
		for (uint256 i; i < _numOfRewardTokens; i++) {
			uint256 toTransfer = blocksAdded * rewardPerBlock[i];
			require(toTransfer > 100, "Too short for increase");
			address taker = factory.getFeeTaker();
			uint256 percent = factory.getFeePercentage();
			uint256 balanceBefore = rewardToken[i].balanceOf(address(this));
			rewardToken[i].safeTransferFrom(msg.sender, address(this), toTransfer);
			uint256 balanceAfter = rewardToken[i].balanceOf(address(this));
			rewardTokenAmounts[i] += balanceAfter - balanceBefore;
			if (!factory.whitelistAddress(address(rewardToken[i]))) {
				rewardToken[i].safeTransferFrom(msg.sender, taker, (toTransfer * percent) / 100);
			}
		}
		endBlock = _endBlock;
	}

	function getRewardTokens() external view returns (ERC20[] memory) {
		return rewardToken;
	}

	/**
	 * @notice View function to see pending reward on frontend.
	 * @param _user: user address
	 * @return Pending reward for a given user
	 */
	function pendingReward(address _user) external view returns (uint256[] memory) {
		require(block.number > startBlock, "Pool is not started yet");
		UserInfo memory user = userInfo[_user];
		uint256[] memory toReturn = new uint256[](_numOfRewardTokens);

		for (uint256 i; i < _numOfRewardTokens; i++) {
			if (block.number > _lastRewardBlock && stakedTokenSupply != 0) {
				uint256 multiplier = _getMultiplier(_lastRewardBlock, block.number);
				uint256 reward = multiplier * (rewardPerBlock[i]);
				uint256 adjustedTokenPerShare = accTokenPerShare[i] + ((reward * (_PRECISION_FACTOR[i])) / (stakedTokenSupply));
				toReturn[i] = (user.amount * (adjustedTokenPerShare)) / (_PRECISION_FACTOR[i]) - (user.rewardDebt[i]);
			} else {
				toReturn[i] = (user.amount * (accTokenPerShare[i])) / (_PRECISION_FACTOR[i]) - (user.rewardDebt[i]);
			}
		}
		return toReturn;
	}

	/**
	 * @notice Update reward variables of the given pool to be up-to-date.
	 */
	function _updatePool() internal {
		if (block.number <= _lastRewardBlock) {
			return;
		}

		if (stakedTokenSupply == 0) {
			_lastRewardBlock = block.number;
			return;
		}

		uint256 multiplier = _getMultiplier(_lastRewardBlock, block.number);
		for (uint256 i; i < _numOfRewardTokens; i++) {
			uint256 reward = multiplier * (rewardPerBlock[i]);
			accTokenPerShare[i] = accTokenPerShare[i] + ((reward * (_PRECISION_FACTOR[i])) / (stakedTokenSupply));
		}
		if (endBlock > block.number) {
			_lastRewardBlock = block.number;
		} else {
			_lastRewardBlock = endBlock;
		}

		if (bonusEndBlock != 0 && block.number > bonusEndBlock) {
			bonusStartBlock = 0;
			bonusEndBlock = 0;
			bonusMultiplier = 1;
		}
	}

	/**
	 * @notice Return reward multiplier over the given from to to block.
	 * @param from: block to start
	 * @param to: block to finish
	 * @return The weighted multiplier for the given period
	 */
	function _getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
		from = from >= startBlock ? from : startBlock;
		to = endBlock > to ? to : endBlock;
		if (from < bonusStartBlock && to > bonusEndBlock) {
			return bonusStartBlock - from + to - bonusEndBlock + (bonusEndBlock - bonusStartBlock) * bonusMultiplier;
		} else if (from < bonusStartBlock && to > bonusStartBlock) {
			return bonusStartBlock - from + (to - bonusStartBlock) * bonusMultiplier;
		} else if (from < bonusEndBlock && to > bonusEndBlock) {
			return to - bonusEndBlock + (bonusEndBlock - from) * bonusMultiplier;
		} else if (from >= bonusStartBlock && to <= bonusEndBlock) {
			return (to - from) * bonusMultiplier;
		} else {
			return to - from;
		}
	}
}
