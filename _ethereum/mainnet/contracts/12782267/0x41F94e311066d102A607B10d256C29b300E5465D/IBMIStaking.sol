// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./ISTKBMIToken.sol";

interface IBMIStaking {
   	event BMIStaked(
		uint256 stakedBMI,
		uint256 mintedStkBMI,
		address indexed recipient
	);

	event BMIWithdrawn(
		uint256 withdrawnBMI,
		uint256 burnedStkBMI,
		address indexed recipient
	);
	
	event UnusedRewardPoolRevoked(address recipient, uint256 amount);

   	function stkBMIToken() external returns (ISTKBMIToken);

   	function stake(uint256 _amountBMI) external;	
   	function withdraw(uint256 _amountStkBMI) external;

   	function stakingReward(uint256 _amount) external view returns (uint256);

   	function getStakedBMI(address _address) external view returns (uint256);

   	function setRewardPerBlock(uint256 _amount) external;

	function revokeUnusedRewardPool() external;
}
