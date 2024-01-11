// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

/// @custom:security-contact info@impact3.io
contract EquityManager is Pausable, AccessControl {
	using SafeMath for uint256;

	event FundsReceived(address indexed addr, uint256 amount);
	event FundsDistributed(uint256 amount);

	bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
	bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

	struct EquityStake {
		address holder;
		uint256 stakePercentage;
		bool revoked;
		uint256 lastReceived;
		uint256 created;
	}

	EquityStake[] public stakeholders;
	uint256 public stakeholderCount;
	address payable public i3Fund;

	constructor(address _i3Fund) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(PAUSER_ROLE, msg.sender);
		_grantRole(MANAGER_ROLE, msg.sender);
		setFund(_i3Fund);
	}

	function setFund(address fund) public onlyRole(MANAGER_ROLE) {
		i3Fund = payable(fund);
	}

	function distributeFunds() public whenNotPaused {
		uint256 fundsToDistribute = address(this).balance;
		uint256 fundsActuallyDistributed = 0;
		for (uint256 i = 0; i < stakeholderCount; i++) {
			if (stakeholders[i].revoked == false) {
				uint256 amount = fundsToDistribute
					.mul(stakeholders[i].stakePercentage)
					.div(100);
				sendValue(payable(stakeholders[i].holder), amount);
				stakeholders[i].lastReceived = block.timestamp;
				fundsActuallyDistributed += amount;
			}
		}
		sendValue(payable(i3Fund), address(this).balance);
		emit FundsDistributed(fundsActuallyDistributed);
	}

	function totalStake() public view returns (uint256) {
		uint256 _totalStake = 0;
		for (uint256 i = 0; i < stakeholderCount; i++) {
			_totalStake += stakeholders[i].stakePercentage;
		}
		return _totalStake;
	}

	function addHolder(address holder, uint256 stake)
		public
		whenNotPaused
		onlyRole(MANAGER_ROLE)
	{
		require(
			totalStake().add(stake) <= 100,
			'Total value staked cannot exceed 100'
		);
		require(stake > 0, 'Stake value must be greater than 0');
		stakeholders.push(
			EquityStake(holder, stake, false, block.timestamp, block.timestamp)
		);
		stakeholderCount++;
	}

	function revokeHolder(address holder) public onlyRole(MANAGER_ROLE) {
		for (uint256 i = 0; i < stakeholderCount; i++) {
			if (stakeholders[i].holder == holder) {
				stakeholders[i].revoked = true;
			}
		}
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			'Contract has insufficient balance'
		);

		(bool success, ) = recipient.call{ value: amount }('');
		require(
			success,
			'Contract is unable to send value, recipient may have reverted'
		);
	}

	function pause() public onlyRole(PAUSER_ROLE) {
		_pause();
	}

	function unpause() public onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	receive() external payable {
		emit FundsReceived(msg.sender, msg.value);
	}
}
