// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./BaseShareField.sol";
import "./Initializable.sol";

interface IONXStrategy {
    function invest(address user, uint256 amount) external; 
    function withdraw(address user, uint256 amount) external;
    function liquidation(address user) external;
    function claim(address user, uint256 amount, uint256 total) external;
    function query() external view returns (uint256);
    function mint() external;
    function interestToken() external view returns (address);
    function farmToken() external view returns (address);
}

interface IONXFarm {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingOnX(uint256 _pid, address _user) external view returns (uint256);
    function poolInfo(uint _index) external view returns(address, uint256, uint256, uint256);
}

contract ONXStrategy is IONXStrategy, BaseShareField, Initializable {
	event Mint(address indexed user, uint256 amount);
	using SafeMath for uint256;
	address public override interestToken;
	address public override farmToken;
	address public poolAddress;
	address public onxFarm;
	uint256 public lpPoolpid;
	address public owner;

	function initialize(
		address _interestToken,
		address _farmToken,
		address _poolAddress,
		address _onxFarm,
		uint256 _lpPoolpid
	) public initializer {
		owner = msg.sender;
		interestToken = _interestToken;
		farmToken = _farmToken;
		poolAddress = _poolAddress;
		onxFarm = _onxFarm;
		lpPoolpid = _lpPoolpid;
		_setShareToken(_interestToken);
	}

	function invest(address user, uint256 amount) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		TransferHelper.safeTransferFrom(farmToken, msg.sender, address(this), amount);
		IERC20(farmToken).approve(onxFarm, amount);
		IONXFarm(onxFarm).deposit(lpPoolpid, amount);
		_increaseProductivity(user, amount);
	}

	function withdraw(address user, uint256 amount) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		IONXFarm(onxFarm).withdraw(lpPoolpid, amount);
		TransferHelper.safeTransfer(farmToken, msg.sender, amount);
		_decreaseProductivity(user, amount);
	}

	function liquidation(address user) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		uint256 amount = users[user].amount;
		_decreaseProductivity(user, amount);
		uint256 reward = users[user].rewardEarn;
		users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.add(reward);
		users[user].rewardEarn = 0;
		_increaseProductivity(msg.sender, amount);
	}

	function claim(
		address user,
		uint256 amount,
		uint256 total
	) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		IONXFarm(onxFarm).withdraw(lpPoolpid, amount);
		TransferHelper.safeTransfer(farmToken, msg.sender, amount);
		_decreaseProductivity(msg.sender, amount);
		uint256 claimAmount = users[msg.sender].rewardEarn.mul(amount).div(total);
		users[user].rewardEarn = users[user].rewardEarn.add(claimAmount);
		users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.sub(claimAmount);
	}

	function _currentReward() internal view override returns (uint256) {
		return
			mintedShare
				.add(IERC20(shareToken).balanceOf(address(this)))
				.add(IONXFarm(onxFarm).pendingOnX(lpPoolpid, address(this)))
				.sub(totalShare);
	}

	function query() external view override returns (uint256) {
		return _takeWithAddress(msg.sender);
	}

	function mint() external override {
		IONXFarm(onxFarm).deposit(lpPoolpid, 0);
		uint256 amount = _mint(msg.sender);
		emit Mint(msg.sender, amount);
	}
}
