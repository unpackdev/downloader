// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./ISTKBrightToken.sol";
import "./IAbstractCooldownStaking.sol";

interface IBrightStaking is IAbstractCooldownStaking{
   	event StakedBright(
		uint256 stakedBright,
		uint256 mintedStkBright,
		address indexed recipient
	);

	event WithdrawnBright(
		uint256 withdrawnBright,
		uint256 burnedStkBright,
		address indexed recipient
	);

	event SweepedUnusedRewards(address recipient, uint256 amount);

   	function stkBrightToken() external returns (ISTKBrightToken);

   	function stake(uint256 _amountBright) external;

	function stakeFor(address _user, uint256 _amountBright) external;

	function stakeWithPermit(uint256 _amountBright, uint8 _v, bytes32 _r, bytes32 _s) external;

	function callWithdraw(uint256 _amountStkBrightUnlock) external;

   	function withdraw() external;

   	function stakingReward(uint256 _amount) external view returns (uint256);

   	function getStakedBright(address _address) external view returns (uint256);

   	function setRewardPerBlock(uint256 _amount) external;

	function sweepUnusedRewards() external;
}
