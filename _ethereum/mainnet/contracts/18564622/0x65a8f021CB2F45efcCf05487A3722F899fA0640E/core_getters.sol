// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./core_state.sol";

contract Core_Getters is Core_State {
	function get_operator() external view returns (address) {
		return _state.operator;
	}

	function get_validator_capacity() external view returns (uint256) {
		return _state.constants.validator_capacity;
	}

	function get_ls_token_contract() external view returns (address) {
		return _state.contracts.ls_token;
	}

	function get_withdraw_contract() external view returns (address) {
		return _state.contracts.withdraw;
	}

	function get_abyss_eth2_depositor_contract() external view returns (address) {
		return _state.contracts.abyss_eth2_depositor;
	}

	function get_user_withdrawal(address user) external view returns (uint256) {
		return _state.withdrawals.withdraw_account[user];
	}

	function get_total_withdrawals() external view returns (uint256) {
		return _state.withdrawals.withdraw_total;
	}

	function get_unstaked_validators() external view returns (uint256) {
		return _state.withdrawals.unstaked_validators;
	}

	// get withdraw contract rewards and protocol rewards
	// calculates rewards not moved to the core contract yet
	function get_wc_rewards() public view returns (uint256, uint256) {
		uint256 rewards;
		if (_state.withdrawals.withdraw_total > 0 || _state.withdrawals.unstaked_validators > 0) {
			uint256 unstaked_validators;
			if (_state.contracts.withdraw.balance > 0) {
				unstaked_validators = _state.contracts.withdraw.balance / _state.constants.validator_capacity;
			}
			if (unstaked_validators > 0) {
				rewards = _state.contracts.withdraw.balance - (unstaked_validators * _state.constants.validator_capacity);
			} else {
				rewards = _state.contracts.withdraw.balance;
			}
		} else {
			rewards = _state.contracts.withdraw.balance;
		}

		// calculate protocol reward
		uint256 protocol_reward = (rewards * _state.protocol_fee_percentage) / 10000000000;

		return (rewards - protocol_reward, protocol_reward);
	}

	// returns all time protocol collected rewards
	function get_total_rewards() external view returns (uint256) {
		(uint256 rewards, ) = get_wc_rewards();
		return _state.distributed_rewards + rewards;
	}

	function get_treasury_address() external view returns (address) {
		return _state.treasury;
	}

	function get_protocol_fee_percentage() external view returns (uint256) {
		return _state.protocol_fee_percentage;
	}

	function get_protocol_rewards() external view returns (uint256) {
		(, uint256 protocol_reward) = get_wc_rewards();
		return _state.protocol_rewards + protocol_reward;
	}

	function get_protocol_float() external view returns (uint256) {
		return _state.protocol_float;
	}

	function get_total_deposits() external view returns (uint256) {
		return _state.total_deposits - _state.distributed_rewards;
	}

	function get_validator_index() external view returns (uint256) {
		return _state.validator_index;
	}
}
