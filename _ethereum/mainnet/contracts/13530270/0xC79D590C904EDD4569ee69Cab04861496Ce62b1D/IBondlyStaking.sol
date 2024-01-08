// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IxBondlyToken.sol";

interface IBondlyStaking {
	event StakedBONDLY(
		uint256 stakedBONDLY,
		uint256 mintedxBONDLY,
		address indexed recipient
	);

	event WithdrawnBONDLY(
		uint256 withdrawnBONDLY,
		uint256 burnedxBONDLY,
		address indexed recipient
	);
	
	event UnusedRewardPoolRevoked(address recipient, uint256 amount);
	
	function xBondlyToken() external returns (IxBondlyToken);
	
	function stake(uint256 _amountBONDLY) external;	
	
	function withdraw(uint256 _amountxBONDLY) external;

	function stakingReward(uint256 _amount) external view returns (uint256);

	function getStakedBONDLY(address _address) external view returns (uint256);

	function setRewardPerBlock(uint256 _amount) external;

	function revokeUnusedRewardPool() external;
}
