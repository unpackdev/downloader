// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IrUSTPool {
	function migrate(address _user, address _borrower, uint256 _amount) external;

	function supplyUSDC(uint256 _amount) external;

	function withdrawUSDC(uint256 _amount) external;

	function supplySTBT(uint256 _amount) external;

	function withdrawSTBT(uint256 _amount) external;

	function withdrawAllSTBT() external;

	function repayUSDC(uint256 _amount) external;

	function borrowUSDC(uint _amount) external;

	function withdrawAllUSDC() external;

	function applyFlashLiquidateProvider() external;

	function cancelFlashLiquidateProvider() external;

	function safeCollateralRate() external view returns (uint256);

	function depositedSharesSTBT(address user) external view returns (uint256);

	function getBorrowedAmount(address user) external view returns (uint256);
}
