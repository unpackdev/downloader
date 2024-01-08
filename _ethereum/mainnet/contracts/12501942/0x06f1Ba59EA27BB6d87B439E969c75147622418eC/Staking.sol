// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

//Staking...
contract Staking is Ownable, Pausable, ReentrancyGuard {
	using SafeMath for uint256;

	struct UserInfo {
		uint256 amount; // current staked BS1
		uint256 createdAt; // unix timestamp when the user created
		uint256 lastUpdateAt; // unix timestamp for last details update (when pointsDebt calculated)
		uint256 pointsDebt; // total points collected before latest deposit
	}

	uint256 public minimumAmount = 1 * (10**18); //1 BS1
	uint256 public maxAmount = 1000 * (10**18); //1000 BS1
	uint256 public lockTime = 30 days;

	//emissionRate - points generated per BS1 token per second staked
	//10000000000 = 0.01 BS1 per 1 BS1 staked 11days
	//10000000000000 = 10 BS1 per 1 BS1 staked 11days [TEST]
	uint256 public emissionRate;

	IERC20 bs1Token; // token being staked
	uint256 public totalRewards; //counting unstaking

	mapping(address => UserInfo) public userInfo;

	event StakeClaimed(address user, uint256 amount);
	event RewardAdded(uint256 amount);
	event EmissionRateChanged(uint256 newEmissionRate);

	constructor(IERC20 _lpToken, uint256 _emissionRate) {
		bs1Token = _lpToken;
		emissionRate = _emissionRate;
		totalRewards = 0;
	}

	// Add reward to the smart contract (must have approval)
	function addReward(uint256 _amount) external {
		bs1Token.transferFrom(msg.sender, address(this), _amount);
		totalRewards = totalRewards + _amount;
		emit RewardAdded(_amount);
	}

	//the core of the contract (must have approval)
	function stake(uint256 _amount) external whenNotPaused nonReentrant {
		require(_amount >= minimumAmount, "amount below minimumAmount");
		require(_amount <= maxAmount, "amount greater than maxAmount");
		require(bs1Token.transferFrom(msg.sender, address(this), _amount), "failed to transfer");
		//BS1 Balance
		require(
			totalRewards >= _amount * emissionRate * lockTime,
			"the owner should topup the rewards"
		); //TODO: CHECK!

		// already deposited before
		UserInfo storage user = userInfo[msg.sender];
		if (user.amount != 0) {
			user.pointsDebt = pointsBalance(msg.sender);
		}

		user.amount = user.amount.add(_amount);
		user.lastUpdateAt = block.timestamp;
		user.createdAt = block.timestamp;
	}

	//get them rewards
	function claim() public nonReentrant {
		UserInfo storage user = userInfo[msg.sender];

		// deduct points
		uint256 amountToTransfer = pointsBalance(msg.sender);
		user.pointsDebt = 0;
		user.lastUpdateAt = block.timestamp;

		totalRewards = totalRewards - amountToTransfer;

		bs1Token.transfer(msg.sender, amountToTransfer);
	}

	function unstake() external {
		UserInfo storage user = userInfo[msg.sender];
		require(user.amount >= 0, "insufficient staked");
		require(user.createdAt + lockTime <= block.timestamp, "tokens are locked");

		// First, send all unclaimed rewards
		claim();

		uint256 userAmount = user.amount;

		totalRewards = totalRewards - userAmount;

		user.amount = 0;

		bs1Token.transfer(msg.sender, userAmount);
	}

	//calculates the undebitted points. (seconds since staked) X emission rate X amount / 10^18
	function _unDebitedPoints(UserInfo memory user) internal view returns (uint256) {
		return block.timestamp.sub(user.lastUpdateAt).mul(emissionRate).mul(user.amount).div(1e18);
	}

	//calculte how many points an address has
	function pointsBalance(address userAddress) public view returns (uint256) {
		UserInfo memory user = userInfo[userAddress];
		return user.pointsDebt.add(_unDebitedPoints(user));
	}

	//change how many BS1 per second you gain (in wei)
	function changeEmissionRate(uint256 newEmissionRate) public onlyOwner {
		emissionRate = newEmissionRate;
		emit EmissionRateChanged(newEmissionRate);
	}

	//change the lockTime
	function changeChangeLockTimeSeconds(uint256 _newLockTime) public onlyOwner {
		lockTime = _newLockTime;
	}

	//owner can withdraw any token sent here
	function reclaimToken(IERC20 token, uint256 _amount) public onlyOwner {
		require(address(token) != address(0), "no 0 address");
		require(address(token) != address(bs1Token), "can't withdraw the reward");
		uint256 balance = token.balanceOf(address(this));
		require(_amount <= balance, "you can't withdraw more than you have");
		token.transfer(msg.sender, _amount);
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	//owner can withdraw any ETH sent here
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}
