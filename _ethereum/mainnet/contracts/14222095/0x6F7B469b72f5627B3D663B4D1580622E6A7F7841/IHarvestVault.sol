// SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;
import "./IERC20.sol";

interface IHarvestVault is IERC20 {
	function underlying() external view returns (address);

	function totalValue() external view returns (uint256);

	function deposit(uint256) external;

	function withdraw(uint256) external;

	function getPricePerFullShare() external view returns (uint256);

	function decimals() external view returns (uint256);
}
