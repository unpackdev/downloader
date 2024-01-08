// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract NineMilkToken is ERC20("9MILK", "9MILK"), Ownable, AccessControl {
	using SafeMath for uint256;

	uint256 public constant BASE_RATE = 9 ether;
	uint256 public constant INITIAL_ISSUANCE = 99 ether;

	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;
	mapping(address => uint256) public stackableBalance;

	uint256 public END = 0;
	uint256 public START = 0;

	bytes32 public constant REWARD_ROLE = keccak256("REWARD_ROLE");

	event RewardPaid(address indexed user, uint256 reward);

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? b : a;
	}

	modifier onlyRewarder() {
		_checkRole(REWARD_ROLE, _msgSender());
		_;
	}

	modifier onlyStarted() {
		require(START > 0, "Not Started");
		_;
	}

	function addRewardRole(address addr) external {
		grantRole(REWARD_ROLE, addr);
	}

	constructor(address ncAddr, address[] memory addrs, uint256[] memory amounts) {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		grantRole(REWARD_ROLE, ncAddr);
		for (uint256 i = 0; i < addrs.length; i++) {
			address addr = addrs[i];
			lastUpdate[addr] = block.timestamp;
			stackableBalance[addr] = amounts[i];
			rewards[addr] = rewards[addr].add(amounts[i].mul(INITIAL_ISSUANCE));
		}
	}

	function startReward() external onlyOwner {
		START = block.timestamp;
		END = START + 283824000;
	}

	// called when minting many NFTs
	function updateRewardOnMint(address _user, uint256 _amount) external onlyRewarder {
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = max(START, lastUpdate[_user]);
		if (timerUser > 0 && START > 0) {
			rewards[_user] = rewards[_user].add(
				stackableBalance[_user].mul(BASE_RATE.mul((time.sub(timerUser)))).div(86400).add(
					_amount.mul(INITIAL_ISSUANCE)
				)
			);
		} else {
			rewards[_user] = rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));
		}
		lastUpdate[_user] = time;
		stackableBalance[_user] += _amount;
	}

	// called on transfers
	function updateReward(
		address _from,
		address _to,
		uint256 balanceChange
	) external onlyRewarder {
		uint256 time = min(block.timestamp, END);
		uint256 timerFrom = max(lastUpdate[_from], START);
		if (timerFrom > 0)
			rewards[_from] += stackableBalance[_from].mul(BASE_RATE.mul((time.sub(timerFrom)))).div(
				86400
			);
		if (timerFrom != END) lastUpdate[_from] = time;
		if (_to != address(0)) {
			uint256 timerTo = max(lastUpdate[_to], START);
			if (timerTo > 0)
				rewards[_to] += stackableBalance[_to].mul(BASE_RATE.mul((time.sub(timerTo)))).div(86400);
			if (timerTo != END) lastUpdate[_to] = time;
		}
		stackableBalance[_from] -= balanceChange;
		if (_to != address(0)) {
			stackableBalance[_to] += balanceChange;
		}
	}

	function getTotalClaimable(address _user) public view onlyStarted returns (uint256) {
		uint256 time = min(block.timestamp, END);
		uint256 u = max(lastUpdate[_user], START);
		uint256 pending = stackableBalance[_user].mul(BASE_RATE.mul((time.sub(u)))).div(86400);
		return rewards[_user] + pending;
	}

	function getReward() external onlyStarted {
		uint256 pending = getTotalClaimable(msg.sender);
		if (pending > 0) {
			lastUpdate[msg.sender] = min(block.timestamp, END);
			rewards[msg.sender] = 0;
			_mint(msg.sender, pending);
			emit RewardPaid(msg.sender, pending);
		}
	}

	function consume(address _from, uint256 _amount) external onlyRewarder {
		_transfer(_from, owner(), _amount);
	}

	function burn(address _from, uint256 _amount) external onlyRewarder {
		_burn(_from, _amount);
	}
}
