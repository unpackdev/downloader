// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract ClaimGoldOfSkulls is Ownable {
	using ECDSA for bytes32;

	event Claim(address indexed to, uint256 value, uint256 nonce);

	address public token;
	mapping(uint256 => bool) usedNonces;

	constructor(address _token) public {
		token = _token;
	}

	function claimPayment(uint256 amount, uint256 nonce, bytes memory signature) public {
		require(!usedNonces[nonce], "Nonce was already used");
		usedNonces[nonce] = true;

		address signer = keccak256(abi.encodePacked(
				toString(msg.sender), Strings.toString(amount), Strings.toString(nonce), toString(address(this))))
		.recover(signature);

		require(signer == owner(), "Signature is wrong");

		require(IERC20(token).transferFrom(owner(), msg.sender, amount), "Transfer is not successful");

		emit Claim(msg.sender, amount, nonce);
	}

	function hasNonce(uint256 nonce) public view returns (bool) {
		return usedNonces[nonce];
	}

	function toString(address account) internal pure returns(string memory) {
		return toString(abi.encodePacked(account));
	}

	function toString(bytes memory data) internal pure returns(string memory) {
		bytes memory alphabet = "0123456789abcdef";

		bytes memory str = new bytes(2 + data.length * 2);
		str[0] = "0";
		str[1] = "x";
		for (uint i = 0; i < data.length; i++) {
			str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
			str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
		}
		return string(str);
	}
}