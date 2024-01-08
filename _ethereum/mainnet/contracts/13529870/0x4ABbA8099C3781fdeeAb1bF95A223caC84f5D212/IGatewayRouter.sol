// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

interface IGatewayRouter {
	function outboundTransfer(
		address _l1Token,
		address _to,
		uint256 _amount,
		uint256 _maxGas,
		uint256 _gasPriceBid,
		bytes calldata _data
	) external payable returns (bytes memory res);

	function setGateway(
		address _gateway,
		uint256 _maxGas,
		uint256 _gasPriceBid,
		uint256 _maxSubmissionCost
	) external payable returns (uint256);
}
