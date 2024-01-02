// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IUSTPController {
	function isUSTPVault(address _vault) external view returns (bool);

	function getUSTPCap() external view returns (uint256);

	function checkMintRisk(address vault) external view returns (bool);

	function checkBurnRisk(address vault) external view returns (bool);
}
