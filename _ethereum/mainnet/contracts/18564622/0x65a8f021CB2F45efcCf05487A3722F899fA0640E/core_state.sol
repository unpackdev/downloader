// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract Core_Storage {
	struct Constants {
		uint256 validator_capacity;
	}

	struct Contracts {
		address ls_token;
		address withdraw;
		address abyss_eth2_depositor;
	}

	struct Withdrawals {
		mapping(address => uint256) withdraw_account;
		uint256 withdraw_total;
		uint256 unstaked_validators; // number of validators pending full withdrawal
	}

	struct State {
		address operator;
		Constants constants;
		Contracts contracts;
		uint256 total_deposits; // total deposits + distributed rewards
		Withdrawals withdrawals;
		uint256 distributed_rewards;
		address treasury;
		uint256 protocol_fee_percentage; // percentage of rewards to be distributed to protocol
		uint256 protocol_rewards; // protocol rewards collected from distributing rewards
		uint256 protocol_float;
		uint256 validator_index;
	}
}

contract Core_State {
	Core_Storage.State _state;
	uint256[50] __gap;
}
