// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SharesFactory.sol";

/**
 * @title EIP712 Typed Struct Library
 *
 * @notice Calculates EIP712 typed structured data typeHash and hashStruct
 */
library TypedStructLib {
	/**
	 * @notice SharesDeploymentRequest typeHash
	 */
	function hashType(SharesFactory.SharesDeploymentRequest calldata) internal pure returns(bytes32) {
		// hashType(SharesDeploymentRequest)
		return 0x7acc9d8c19a06f50ae6d92c5e1206302e8aeac9f7f8bf014389ca2a4354650fd;
	}

	/**
	 * @notice SharesSubject typeHash
	 */
	function hashType(TradeableShares.SharesSubject calldata) internal pure returns(bytes32) {
		// hashType(SharesSubject) = keccak256("SharesSubject(address tokenAddress,uint256 tokenId)")
		return 0x685dd8e2693cf377e50b3e95f06b61dff4c1705fa19df1071074d64f4e1469eb;
	}

	/**
	 * @notice SharesDeploymentRequest hashStruct
	 */
	function hashStruct(SharesFactory.SharesDeploymentRequest calldata request) internal pure returns(bytes32) {
		return keccak256(abi.encode(
			hashType(request),
			request.implementationType,
			hashStruct(request.sharesSubject),
			request.issuer,
			request.amount,
			request.validFromTimestamp,
			request.expiresAtTimestamp,
			request.nonce
		));
	}

	/**
	 * @notice SharesSubject hashStruct
	 */
	function hashStruct(TradeableShares.SharesSubject calldata sharesSubject) internal pure returns(bytes32) {
		return keccak256(abi.encode(
			hashType(sharesSubject),
			sharesSubject.tokenAddress,
			sharesSubject.tokenId
		));
	}

}
