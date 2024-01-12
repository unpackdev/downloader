// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title BespokeStrings
/// @dev Custom strings library that is separately unit tested
library BespokeStrings {

	/// Returns the entire path d attribute described by the stream of input bytes
	/// @param path Computer-generated stream of bytes that represents the entire d attribute
	/// @return string containing the entire path element's d attribute
	function fullPathAttribute(bytes memory path) internal pure returns (string memory) {
		unchecked {
			string memory dAttribute = "";
			uint index = 0;
			uint stop = path.length;
			while (index < stop) {
				bytes1 control = path[index++];
				dAttribute = string(abi.encodePacked(dAttribute, control));
				if (control == "C") {
					dAttribute = string.concat(dAttribute,
						BespokeStrings.stringFromBytes2(path, index), " ",
						BespokeStrings.stringFromBytes2(path, index + 2), " ",
						BespokeStrings.stringFromBytes2(path, index + 4), " ",
						BespokeStrings.stringFromBytes2(path, index + 6), " ",
						BespokeStrings.stringFromBytes2(path, index + 8), " ",
						BespokeStrings.stringFromBytes2(path, index + 10)
					);
					index += 12;
				} else if (control == "L" || control == "M") {
					dAttribute = string.concat(dAttribute,
						BespokeStrings.stringFromBytes2(path, index), " ",
						BespokeStrings.stringFromBytes2(path, index + 2)
					);
					index += 4;
				} else if (control == "H" || control == "V") {
					dAttribute = string.concat(dAttribute,
						BespokeStrings.stringFromBytes2(path, index)
					);
					index += 2;
				}
			}
			// require(index == stop, dAttribute);
			return dAttribute;
		}
	}

	/// Returns the d attribute between M and Z
	/// @dev Simple path consists of one M followed by repeated C's
	/// @param path Computer-generated stream of bytes that represents the d attribute
	/// @return string containing the text between the M and Z characters
	function simplePathAttribute(bytes memory path) internal pure returns (string memory) {
		unchecked {
			// Simple path starts with M
			string memory dAttribute = string.concat(
				BespokeStrings.stringFromBytes2(path, 0), " ",
				BespokeStrings.stringFromBytes2(path, 2)
			);
			uint index = 4;
			uint stop = path.length;
			while (index < stop) {
				dAttribute = string.concat(dAttribute,
					"C", BespokeStrings.stringFromBytes2(path, index),
					" ", BespokeStrings.stringFromBytes2(path, index + 2),
					" ", BespokeStrings.stringFromBytes2(path, index + 4),
					" ", BespokeStrings.stringFromBytes2(path, index + 6),
					" ", BespokeStrings.stringFromBytes2(path, index + 8),
					" ", BespokeStrings.stringFromBytes2(path, index + 10));
				index += 12;
			}
			// require(index == stop, dAttribute);
			return dAttribute;
		}
	}

	/// Converts a 2-byte number within a bytes stream into a decimal string
	/// @dev This function is optimized and unit-tested against a reference version written in pure Solidity
	/// @param encoded The stream of bytes containing 2-byte unsigned integers
	/// @param startIndex The index within the `encoded` bytes to parse
	/// @return a decimal string representing the 2-byte unsigned integer
	function stringFromBytes2(bytes memory encoded, uint256 startIndex) internal pure returns (string memory) {

		// Pull the value from `encoded` starting at `startIndex`
		uint value;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			// Load 2 bytes into `value` as uint from `encoded` starting at `startIndex`
			value := shr(240, mload(add(add(encoded, 32), startIndex))) // 240 = 256 - 16 bits
		}

		// Create the byte buffer -- optimized for a max of 5 digits, which represents any 16 bit number
		uint digits = value > 9999 ? 5 : value > 999 ? 4 : value > 99 ? 3 : value > 9 ? 2 : 1;
		bytes memory buffer = new bytes(digits);

		// Convert each digit to ascii starting from the least significant digit
		// solhint-disable-next-line no-inline-assembly
		assembly {
			for {
				// Calculate the starting address into buffer's data
				let bufferDataStart := add(buffer, 32)
				// Initialize the pointer to the least-significant digit
				let bufferDataPtr := add(bufferDataStart, digits)
			} gt(bufferDataPtr, bufferDataStart) { // While pointer > start index (don't check `value` because it could be 0)
				// divide `value` by 10 to get the next digit
				value := div(value, 10)
			} {
				// subtract the pointer before assigning to the buffer
				bufferDataPtr := sub(bufferDataPtr, 1)
				// assign the ascii value of the least-significant digit to the buffer
				mstore8(bufferDataPtr, add(48, mod(value, 10)))
			}
		}

		// Return the bytes buffer as a string
		return string(buffer);
	}
}
