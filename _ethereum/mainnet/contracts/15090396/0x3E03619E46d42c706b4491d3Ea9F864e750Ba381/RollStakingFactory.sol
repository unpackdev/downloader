// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./Initializable.sol";
import "./RollStakingRewards.sol";
import "./StakingRegistry.sol";

contract RollStakingFactory is Initializable {
	IStakingRegistry public registry;

	function initialize(address _registry) public initializer {
		require(_registry != address(0), "Registry address cannot be 0");
		registry = IStakingRegistry(_registry);
	}

	event Deployed(address stakingContract);

	function createStakingContract(
		address[] memory _rewardTokens,
		address _stakedToken
	) external returns (address) {
		RollStakingRewards stakingContract = new RollStakingRewards(
			msg.sender,
			msg.sender,
			_rewardTokens,
			_stakedToken,
			address(registry)
		);
		registry.setCaller(address(stakingContract), true);
		registry.assignOwnerToContract(
			address(stakingContract),
			msg.sender,
			address(0)
		);
		emit Deployed(address(stakingContract));
		return address(stakingContract);
	}
}
