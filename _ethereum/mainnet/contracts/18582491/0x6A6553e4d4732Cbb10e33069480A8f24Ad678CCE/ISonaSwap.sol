// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6;

interface ISonaSwap {
	function getUsdEthPrice() external view returns (uint256 price);

	function swapWEthForUSDC(uint256 _amount) external returns (uint256 amountOut);

	function swapEthForUSDC() external payable returns (uint256 amountOut);

	function getQuote(
		uint256 _amount,
		uint256 _rate
	) external pure returns (uint256 minimumAmount) ;

	function getQuote(
		uint256 _amount
	) external view returns (uint256 minimumAmount);
}
