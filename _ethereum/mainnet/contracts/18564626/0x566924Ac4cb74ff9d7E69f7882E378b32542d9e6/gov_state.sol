// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract Gov_Storage {
	struct Contracts {
		address gov_token;
		address sgov_token;
	}

	struct Emission {
		uint256 em_rate;
		uint256 acc_emissions_per_share;
		uint256 last_emissions_block;
	}

	struct User_Data {
		bool is_staking;
		uint256 staked_balance;
		uint256 emissions_debt;
		uint256 unclaimed_emissions;
		uint256 last_vp_block;
		uint256 voting_power;
	}

	struct State {
		Contracts contracts;
		address treasury;
		uint256 protocol_fee_percentage; // percentage of rewards to be distributed to protocol
		address[] stakers;
		mapping(address => uint256) staker_index; // + 1 to distinguish from default value 0
		mapping(address => User_Data) user_data;
		Emission emission;
		uint256 total_staked;
		uint256 vp_rate;
		uint256 total_vp;
	}
}

contract Gov_State {
	Gov_Storage.State _state;
	uint256[50] __gap;
}
