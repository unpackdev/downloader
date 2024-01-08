// Be name Khoda
// Bime Abolfazl

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ======================= STAKING ======================
// ======================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// Hosein: https://github.com/hedzed

// Reviewer(s) / Contributor(s)
// S.A. Yaghoubnejad: https://github.com/SAYaghoubnejad
// Hosein: https://github.com/hedzed

pragma solidity 0.8.9;

import "./AccessControl.sol";

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface DEUSToken {
	function pool_mint(address m_address, uint256 m_amount) external;
}

contract Staking is AccessControl {

	struct User {
		uint256 depositAmount;
		uint256 paidReward;
	}

	mapping (address => User) public users;

	uint256 public rewardTillNowPerToken = 0;
	uint256 public lastUpdatedBlock;
	uint256 public rewardPerBlock;
	uint256 public scale = 1e18;

	uint256 public particleCollector = 0;
	uint256 public daoShare;
	uint256 public earlyFoundersShare;
	address public daoWallet;
	address public earlyFoundersWallet;
	uint256 public totalStakedToken = 1;  // init with 1 instead of 0 to avoid division by zero

	address public stakedToken;
	address public rewardToken;

	bytes32 private constant REWARD_PER_BLOCK_SETTER = keccak256("REWARD_PER_BLOCK_SETTER");
	bytes32 private constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");

	/* ========== CONSTRUCTOR ========== */

	constructor (
		address _stakedToken,
		address _rewardToken,
		uint256 _rewardPerBlock,
		uint256 _daoShare,
		uint256 _earlyFoundersShare,
		address _daoWallet,
		address _earlyFoundersWallet,
		address _rewardPerBlockSetter)
	{
		require(
			_stakedToken != address(0) &&
			_rewardToken != address(0) &&
			_daoWallet != address(0) &&
			_earlyFoundersWallet != address(0),
			"STAKING::constructor: Zero address detected"
		);
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(REWARD_PER_BLOCK_SETTER, _rewardPerBlockSetter);
		_setupRole(TRUSTY_ROLE, msg.sender);
		stakedToken = _stakedToken;
		rewardToken = _rewardToken;
		rewardPerBlock = _rewardPerBlock;
		daoShare = _daoShare;
		earlyFoundersShare = _earlyFoundersShare;
		lastUpdatedBlock = block.number;
		daoWallet = _daoWallet;
		earlyFoundersWallet = _earlyFoundersWallet;
	}


	modifier onlyTrusty() {
		require(hasRole(TRUSTY_ROLE, msg.sender), "STAKING:: Caller is not a trusty");
		_;
	}

	/* ========== VIEWS ========== */

	// View function to see pending reward on frontend.
	function pendingReward(address _user) external view returns (uint256 reward) {
		User storage user = users[_user];
		uint256 accRewardPerToken = rewardTillNowPerToken;

		if (block.number > lastUpdatedBlock) {
			uint256 rewardAmount = (block.number - lastUpdatedBlock) * rewardPerBlock;
			accRewardPerToken = accRewardPerToken + (rewardAmount * scale / totalStakedToken);
		}
		reward = (user.depositAmount * accRewardPerToken / scale) - user.paidReward;
	}

	/* ========== PUBLIC FUNCTIONS ========== */

	// Update reward variables of the pool to be up-to-date.
	function update() public {
		if (block.number <= lastUpdatedBlock) {
			return;
		}

		uint256 rewardAmount = (block.number - lastUpdatedBlock) * rewardPerBlock;

		rewardTillNowPerToken = rewardTillNowPerToken + (rewardAmount * scale / totalStakedToken);
		lastUpdatedBlock = block.number;
	}

	function deposit(uint256 amount) external {
		depositFor(msg.sender, amount);
	}

	function depositFor(address _user, uint256 amount) public {
		User storage user = users[_user];
		update();

		if (user.depositAmount > 0) {
			uint256 _pendingReward = (user.depositAmount * rewardTillNowPerToken / scale) - user.paidReward;
			sendReward(_user, _pendingReward);
		}

		user.depositAmount = user.depositAmount + amount;
		user.paidReward = user.depositAmount * rewardTillNowPerToken / scale;

		IERC20(stakedToken).transferFrom(msg.sender, address(this), amount);
		totalStakedToken = totalStakedToken + amount;
		emit Deposit(_user, amount);
	}

	function withdraw(uint256 amount) external {
		User storage user = users[msg.sender];
		require(user.depositAmount >= amount, "STAKING::withdraw: withdraw amount exceeds deposited amount");
		update();

		uint256 _pendingReward = (user.depositAmount * rewardTillNowPerToken / scale) - user.paidReward;
		sendReward(msg.sender, _pendingReward);

		uint256 particleCollectorShare = _pendingReward * (daoShare + earlyFoundersShare) / scale;
		particleCollector = particleCollector + particleCollectorShare;

		if (amount > 0) {
			user.depositAmount = user.depositAmount - amount;
			IERC20(stakedToken).transfer(address(msg.sender), amount);
			totalStakedToken = totalStakedToken - amount;
			emit Withdraw(msg.sender, amount);
		}

		user.paidReward = user.depositAmount * rewardTillNowPerToken / scale;
	}

	function withdrawParticleCollector() public {
		uint256 _daoShare = particleCollector * daoShare / (daoShare + earlyFoundersShare);
		DEUSToken(rewardToken).pool_mint(daoWallet, _daoShare);

		uint256 _earlyFoundersShare = particleCollector * earlyFoundersShare / (daoShare + earlyFoundersShare);
		DEUSToken(rewardToken).pool_mint(earlyFoundersWallet, _earlyFoundersShare);

		particleCollector = 0;

		emit WithdrawParticleCollectorAmount(_earlyFoundersShare, _daoShare);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw() external {
		User storage user = users[msg.sender];

		totalStakedToken = totalStakedToken - user.depositAmount;

		IERC20(stakedToken).transfer(msg.sender, user.depositAmount);
		emit EmergencyWithdraw(msg.sender, user.depositAmount);

		user.depositAmount = 0;
		user.paidReward = 0;
	}

	function sendReward(address user, uint256 amount) internal {
		// uint256 _daoShareAndEarlyFoundersShare = amount * (daoShare + earlyFoundersShare) / scale;
		// DEUSToken(rewardToken).pool_mint(user, amount - _daoShareAndEarlyFoundersShare);
		DEUSToken(rewardToken).pool_mint(user, amount);
		emit RewardClaimed(user, amount);
	}

	/* ========== EMERGENCY FUNCTIONS ========== */

	// Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
	// Contract ownership will transfer to address(0x) after full auditing of codes.
	function withdrawAllStakedtokens(address to) external onlyTrusty {
		uint256 totalStakedTokens = IERC20(stakedToken).balanceOf(address(this));
		totalStakedToken = 1;
		IERC20(stakedToken).transfer(to, totalStakedTokens);

		emit withdrawStakedtokens(totalStakedTokens, to);
	}

	function setStakedToken(address _stakedToken) external onlyTrusty {
		stakedToken = _stakedToken;

		emit StakedTokenSet(_stakedToken);
	}

	function emergencyWithdrawERC20(address to, address _token, uint256 amount) external onlyTrusty {
		IERC20(_token).transfer(to, amount);
	}
	function emergencyWithdrawETH(address payable to, uint amount) external onlyTrusty {
		payable(to).transfer(amount);
	}

	function setWallets(address _daoWallet, address _earlyFoundersWallet) external onlyTrusty {
		daoWallet = _daoWallet;
		earlyFoundersWallet = _earlyFoundersWallet;

		emit WalletsSet(_daoWallet, _earlyFoundersWallet);
	}

	function setShares(uint256 _daoShare, uint256 _earlyFoundersShare) external onlyTrusty {
		withdrawParticleCollector();
		daoShare = _daoShare;
		earlyFoundersShare = _earlyFoundersShare;

		emit SharesSet(_daoShare, _earlyFoundersShare);
	}

	function setRewardPerBlock(uint256 _rewardPerBlock) external {
		require(hasRole(REWARD_PER_BLOCK_SETTER, msg.sender), "STAKING::setRewardPerBlock: Caller is not a rewardPerBlockSetter");
		update();
		emit RewardPerBlockChanged(rewardPerBlock, _rewardPerBlock);
		rewardPerBlock = _rewardPerBlock;
	}


	/* ========== EVENTS ========== */

	event withdrawStakedtokens(uint256 totalStakedTokens, address to);
	event StakedTokenSet(address _stakedToken);
	event SharesSet(uint256 _daoShare, uint256 _earlyFoundersShare);
	event WithdrawParticleCollectorAmount(uint256 _earlyFoundersShare, uint256 _daoShare);
	event WalletsSet(address _daoWallet, address _earlyFoundersWallet);
	event Deposit(address user, uint256 amount);
	event Withdraw(address user, uint256 amount);
	event EmergencyWithdraw(address user, uint256 amount);
	event RewardClaimed(address user, uint256 amount);
	event RewardPerBlockChanged(uint256 oldValue, uint256 newValue);
}

//Dar panah khoda