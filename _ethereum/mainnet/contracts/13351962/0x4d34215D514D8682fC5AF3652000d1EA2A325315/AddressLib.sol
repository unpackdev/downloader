// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

// see https://ethereum.stackexchange.com/questions/63908/address-checksum-solidity-implementation
library AddressLib {
	function toChecksumString(address account)
		internal
		pure
		returns (string memory asciiString)
	{
		// convert the account argument from address to bytes.
		bytes20 data = bytes20(account);

		// create an in-memory fixed-size bytes array.
		bytes memory asciiBytes = new bytes(40);

		// declare variable types.
		uint8 b;
		uint8 leftNibble;
		uint8 rightNibble;
		bool leftCaps;
		bool rightCaps;
		uint8 asciiOffset;

		// get the capitalized characters in the actual checksum.
		bool[40] memory caps = _toChecksumCapsFlags(account);

		// iterate over bytes, processing left and right nibble in each iteration.
		for (uint256 i = 0; i < data.length; i++) {
			// locate the byte and extract each nibble.
			b = uint8(uint160(data) / (2**(8 * (19 - i))));
			leftNibble = b / 16;
			rightNibble = b - 16 * leftNibble;

			// locate and extract each capitalization status.
			leftCaps = caps[2 * i];
			rightCaps = caps[2 * i + 1];

			// get the offset from nibble value to ascii character for left nibble.
			asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

			// add the converted character to the byte array.
			asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset)[0];

			// get the offset from nibble value to ascii character for right nibble.
			asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

			// add the converted character to the byte array.
			asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset)[0];
		}

		return string(abi.encodePacked("0x", string(asciiBytes)));
	}

	function _toChecksumCapsFlags(address account)
		private
		pure
		returns (bool[40] memory characterCapitalized)
	{
		// convert the address to bytes.
		bytes20 a = bytes20(account);

		// hash the address (used to calculate checksum).
		bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

		// declare variable types.
		uint8 leftNibbleAddress;
		uint8 rightNibbleAddress;
		uint8 leftNibbleHash;
		uint8 rightNibbleHash;

		// iterate over bytes, processing left and right nibble in each iteration.
		for (uint256 i; i < a.length; i++) {
			// locate the byte and extract each nibble for the address and the hash.
			rightNibbleAddress = uint8(a[i]) % 16;
			leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
			rightNibbleHash = uint8(b[i]) % 16;
			leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

			characterCapitalized[2 * i] = (leftNibbleAddress > 9 &&
				leftNibbleHash > 7);
			characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 &&
				rightNibbleHash > 7);
		}
	}

	function _getAsciiOffset(uint8 nibble, bool caps)
		private
		pure
		returns (uint8 offset)
	{
		// to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
		if (nibble < 10) {
			offset = 48;
		} else if (caps) {
			offset = 55;
		} else {
			offset = 87;
		}
	}

	function _toAsciiString(bytes20 data)
		private
		pure
		returns (string memory asciiString)
	{
		// create an in-memory fixed-size bytes array.
		bytes memory asciiBytes = new bytes(40);

		// declare variable types.
		uint8 b;
		uint8 leftNibble;
		uint8 rightNibble;

		// iterate over bytes, processing left and right nibble in each iteration.
		for (uint256 i = 0; i < data.length; i++) {
			// locate the byte and extract each nibble.
			b = uint8(uint160(data) / (2**(8 * (19 - i))));
			leftNibble = b / 16;
			rightNibble = b - 16 * leftNibble;

			// to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
			asciiBytes[2 * i] = bytes1(
				leftNibble + (leftNibble < 10 ? 48 : 87)
			)[0];
			asciiBytes[2 * i + 1] = bytes1(
				rightNibble + (rightNibble < 10 ? 48 : 87)
			)[0];
		}

		return string(asciiBytes);
	}
}
