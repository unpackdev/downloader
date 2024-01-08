// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

interface ICustomGateway {
	function registerTokenToL2(
		address _l2CustomTokenAddress,
		uint256 _maxGas,
		uint256 _gasPriceBid,
		uint256 _maxSubmissionCostForCustomBridge
	) external payable;
}
