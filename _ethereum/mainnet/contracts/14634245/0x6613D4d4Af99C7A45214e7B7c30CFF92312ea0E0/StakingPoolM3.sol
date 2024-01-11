//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

// $KEY interface
interface KeyIERC20 is IERC20 {
	function hasReachedCap() external view returns (bool);

	function mint(address to, uint256 amount) external payable returns (bool);

	function decimals() external view returns (uint8);
}

/** @title Staking Pool. */
contract StakingPoolM3 is
	ReentrancyGuard,
	Pausable,
	AccessControl,
	IERC721Receiver
{
	// defensive as not required after pragma ^0.8
	using SafeMath for uint256;

	// access control roles
	bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
	bytes32 public constant MANAGER_ROLE = keccak256('MANGER_ROLE');

	// $KEY token
	KeyIERC20 public rewardsToken;
	// $1CLB token
	IERC721 public stakingToken;
	// $KEY reward initialised for staking period
	uint256 public rewardForPeriod = 6 * (10**18);
	// reward period fixed in days
	uint256 public stakePeriod = 84 days;
	// reward payout per second
	uint256 public stakeRewardsPerSecond = rewardForPeriod / stakePeriod;

	// reward payout once staking period ends
	uint256 private _minimumStakePeriod = 28 days;
	// amounts to 0.5 $KEY for the entirety of staking period
	uint256 private _minimumRewardForPeriod = 5 * (10**17);

	// stake object
	struct Stake {
		uint256 tokenId; // tokenID of $1CLB NFT
		uint256 startTime; // timestamp of when NFT was staked
		uint256 lastClaim; // timestamp of when last claim was made
		bool isStake; // needs a manual check to distinguish a default from an explicitly "all 0" record
	}

	// track stakeholders X has list of stakes
	mapping(address => Stake[]) public stakeHolders;

	// emitted when stake function is called
	event Staked(uint256 tokenId);

	constructor(address _stakingToken, address _rewardsToken) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(MANAGER_ROLE, msg.sender);
		_grantRole(PAUSER_ROLE, msg.sender);
		setStakingToken(_stakingToken);
		setRewardToken(_rewardsToken);
	}

	/** @dev Set stake reward for period
	 * @param reward reward amount in WEI
	 */
	function setStakeRewardForPeriod(uint256 reward)
		public
		onlyRole(MANAGER_ROLE)
	{
		rewardForPeriod = reward;
	}

	/** @dev Sets the staking token of the contract
	 * @param _stakingToken address to the $1CLB contract
	 */
	function setStakingToken(address _stakingToken)
		public
		onlyRole(MANAGER_ROLE)
	{
		stakingToken = IERC721(_stakingToken);
	}

	/** @dev Sets the reward token the contract
	 * @param _rewardsToken address to the $KEY contract
	 */
	function setRewardToken(address _rewardsToken)
		public
		onlyRole(MANAGER_ROLE)
	{
		rewardsToken = KeyIERC20(_rewardsToken);
	}

	/** @dev Pauses the contract
	 */
	function pause() public onlyRole(PAUSER_ROLE) {
		_pause();
	}

	/** @dev Unpauses the contract
	 */
	function unpause() public onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	/** @dev Calculates the staking reward for a given owner and tokenId.
	 * @param _owner Address of the owner.
	 * @param _tokenId Id of the NFT.
	 * @return keyRewards The calculated reward rate.
	 */
	function calculateReward(address _owner, uint256 _tokenId)
		public
		view
		returns (uint256)
	{
		// check if key tokens have already reached its maximum supply
		if (rewardsToken.hasReachedCap()) return 0;

		// this will revert if no tokenId found for owner
		Stake memory currentStake = getStakeWithTokenId(_owner, _tokenId);

		uint256 stakeEndTime = calculateLockTime(currentStake.startTime);

		// Check if stake has ended
		if (block.timestamp > stakeEndTime) {
			// calculate remaining rewards from last claim to end of stake period
			uint256 _timeElapsedSinceLastClaim = stakeEndTime -
				currentStake.lastClaim;
			uint256 timeElapsedSinceEndStake = block.timestamp - stakeEndTime;

			uint256 minStakeRewardPerMS = _minimumRewardForPeriod /
				_minimumStakePeriod;

			uint256 _rewardsForTimeElapsed = stakeRewardsPerSecond *
				_timeElapsedSinceLastClaim;
			uint256 rewardsForTimeElapsedAfterStake = minStakeRewardPerMS *
				timeElapsedSinceEndStake;

			return (_rewardsForTimeElapsed + rewardsForTimeElapsedAfterStake);
		}

		uint256 timeElapsedSinceLastClaim = block.timestamp -
			currentStake.lastClaim;
		uint256 rewardsForTimeElapsed = stakeRewardsPerSecond *
			timeElapsedSinceLastClaim;

		return rewardsForTimeElapsed;
	}

	/** @dev Calculates the lock-up period for a given staking start time.
	 * @param _startTime Starting time of stake.
	 * @return lockup The calculated lockup period.
	 */
	function calculateLockTime(uint256 _startTime)
		public
		view
		returns (uint256)
	{
		return _startTime + stakePeriod;
	}

	/** @dev Retrieves the stake objects for a given owner.
	 * @param _owner Address of the owner.
	 * @return stake The Stake array.
	 */
	function getStakes(address _owner) external view returns (Stake[] memory) {
		return stakeHolders[_owner];
	}

	/** @dev Retrieves the stake object for a given owner and token Id.
	 * @param _owner Address of the owner.
	 * @param _tokenId Id of the token.
	 * @return stake The Stake struct.
	 */
	function getStakeWithTokenId(address _owner, uint256 _tokenId)
		public
		view
		returns (Stake memory)
	{
		Stake[] memory currentStakes = this.getStakes(_owner);
		for (uint256 i = 0; i < currentStakes.length; i++) {
			if (currentStakes[i].tokenId == _tokenId) {
				return currentStakes[i];
			}
		}
		revert('Token is not staked by owner');
	}

	/** @dev Stakes the tokenId if caller came through a gold invitation.
	 * @param _tokenId Id of the token.
	 */
	function goldStake(address _owner, uint256 _tokenId) external {
		require(
			msg.sender == address(stakingToken),
			'caller must be token contract'
		);

		// push object to stakeHolder mapping
		stakeHolders[_owner].push(
			Stake(_tokenId, block.timestamp, block.timestamp, true)
		);

		// emit event
		emit Staked(_tokenId);
	}

	/** @dev Stakes the tokenId.
	 * @param _tokenId Id of the token.
	 */
	function stake(uint256 _tokenId) external whenNotPaused {
		// transfer NFT from caller to contract
		// will fail if NFT is already in this contract
		stakingToken.transferFrom(msg.sender, address(this), _tokenId);

		// create Stake object
		Stake memory newStake = Stake({
			tokenId: _tokenId,
			startTime: block.timestamp,
			lastClaim: block.timestamp,
			isStake: true
		});

		// push object to stakeHolder mapping
		stakeHolders[msg.sender].push(newStake);

		// emit event
		emit Staked(_tokenId);
	}

	/** @dev Claims the reward for a given tokenId.
	 * @param _tokenId Id of the token.
	 */
	function claimReward(uint256 _tokenId) public whenNotPaused {
		uint256 rewards = calculateReward(msg.sender, _tokenId);

		// mint amount of $KEY tokens to sender
		(bool success, bytes memory returnedData) = address(rewardsToken).call(
			abi.encodeWithSignature(
				'mint(address,uint256)',
				msg.sender,
				rewards
			)
		);

		require(success, string(returnedData));
		_updateStakeClaimTime(msg.sender, _tokenId);
	}

	/** @dev Claims the reward and withdraws the stake for a given tokenId.
	 * @param _tokenId Id of the token.
	 */
	function claimRewardAndWithdrawStake(uint256 _tokenId)
		external
		whenNotPaused
	{
		claimReward(_tokenId);
		withdrawStake(_tokenId);
	}

	/** @dev Forfeits any remaining reward and withdraws the stake for a given tokenId.
	 * @param _tokenId Id of the token.
	 */
	function withdrawStake(uint256 _tokenId) public whenNotPaused {
		Stake memory currentStake = getStakeWithTokenId(msg.sender, _tokenId);
		// ensure lockup time is expired
		require(
			calculateLockTime(currentStake.startTime) <= block.timestamp,
			'Lock up period has not expired yet'
		);

		for (uint256 i = 0; i < stakeHolders[msg.sender].length; i++) {
			if (stakeHolders[msg.sender][i].tokenId == _tokenId) {
				stakeHolders[msg.sender][i].isStake = false; // defensive
				delete stakeHolders[msg.sender];
			}
		}
		stakingToken.transferFrom(address(this), msg.sender, _tokenId);
	}

	/** @dev Re-stakes the NFT if not withdrawn and lockup time has expired
	 * @param _tokenId Id of the token.
	 */
	function claimAndReStake(uint256 _tokenId) public whenNotPaused {
		Stake memory currentStake = getStakeWithTokenId(msg.sender, _tokenId);
		// ensure lockup time is expired
		require(
			calculateLockTime(currentStake.startTime) <= block.timestamp,
			'Lock up period has not expired yet'
		);

		claimReward(_tokenId);

		// create Stake object
		Stake memory newStake = Stake({
			tokenId: _tokenId,
			startTime: block.timestamp,
			lastClaim: block.timestamp,
			isStake: true
		});

		for (uint256 i = 0; i < stakeHolders[msg.sender].length; i++) {
			if (stakeHolders[msg.sender][i].tokenId == _tokenId) {
				// replace object in stakeHolder mapping
				stakeHolders[msg.sender][i] = newStake;
			}
		}

		// emit event
		emit Staked(_tokenId);
	}

	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes memory _data
	) public pure override returns (bytes4) {
		return this.onERC721Received.selector;
	}

	/** @dev Updates the claim time for a given stake
	 * @param _owner owner of the stake.
	 * @param _tokenId Id of the token.
	 */
	function _updateStakeClaimTime(address _owner, uint256 _tokenId) private {
		for (uint256 i = 0; i < stakeHolders[_owner].length; i++) {
			if (stakeHolders[_owner][i].tokenId == _tokenId) {
				// check if claim happened after stake expiry
				uint256 stakeExpiry = calculateLockTime(
					stakeHolders[_owner][i].startTime
				);
				// if stake time expired
				if (stakeExpiry < block.timestamp) {
					// update object for stakeHolder
					stakeHolders[_owner][i].lastClaim = stakeExpiry;
				} else {
					// update object for stakeHolder
					stakeHolders[_owner][i].lastClaim = block.timestamp;
				}
			}
		}
	}
}
