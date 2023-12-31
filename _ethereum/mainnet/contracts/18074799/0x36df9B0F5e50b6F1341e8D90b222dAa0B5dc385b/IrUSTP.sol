// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IrUSTP {
	function getSharesByrUSTPAmount(uint256 _rUSTPAmount) external view returns (uint256);

	function getrUSTPAmountByShares(uint256 _sharesAmount) external view returns (uint256);

	function sharesOf(address _account) external view returns (uint256);
}
