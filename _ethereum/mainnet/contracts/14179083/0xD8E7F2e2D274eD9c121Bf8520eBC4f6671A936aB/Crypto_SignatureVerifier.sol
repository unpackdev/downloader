// SPDX-License-Identifier: AGPL-1.0-only

pragma solidity ^0.8.0;

/// @custom:security-contact privacy-admin@supremacy.game
contract SignatureVerifier {
	address public signer;

	constructor(address _signer) {
		signer = _signer;
	}

	function setSigner(address _signer) internal {
		signer = _signer;
	}

	// verify returns true if signature by signer matches the hash
	function verify(bytes32 messageHash, bytes memory signature)
		internal
		view
		returns (bool)
	{
		bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

		return recoverSigner(ethSignedMessageHash, signature) == signer;
	}

	function getEthSignedMessageHash(bytes32 messageHash)
		internal
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked(
					"\x19Ethereum Signed Message:\n32",
					messageHash
				)
			);
	}

	function recoverSigner(
		bytes32 _ethSignedMessageHash,
		bytes memory _signature
	) internal pure returns (address) {
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

		return ecrecover(_ethSignedMessageHash, v, r, s);
	}

	function splitSignature(bytes memory signature)
		internal
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(signature.length == 65, "invalid signature length");

		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := byte(0, mload(add(signature, 96)))
		}
	}
}
