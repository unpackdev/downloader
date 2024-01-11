// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

interface IGnosisSafe {
	function signedMessages(bytes32 _key) external view returns (uint256);

	function checkSignatures(
		bytes32 dataHash,
		bytes memory data,
		bytes memory signatures
	) external view;

	function domainSeparator() external view returns (bytes32);

	function getModulesPaginated(address start, uint256 pageSize)
		external
		view
		returns (address[] memory array, address next);
}
