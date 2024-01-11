// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Land Blob Library
 *
 * @dev A library to support `mintingBlob` parsing supplied into `mintFor`
 *      NFT minting function executed when withdrawing an NFT from L2 into L1
 *
 * @dev The blob supplied is a bytes string having the `{tokenId}:{metadata}`
 *      format which needs to be parsed more effectively than `imx-contracts`
 *      does currently
 *
 * @dev This library implements the `parseMintingBlob` function which
 *      iterates over the blob only once and extracts `tokenId` and `metadata` from it
 *
 * @author Basil Gorin
 */
library LandBlobLib {
	/**
	 * @dev Simplified version of StringUtils.atoi to convert a bytes string
	 *      to unsigned integer using ten as a base
	 * @dev Stops on invalid input (wrong character for base ten) and returns
	 *      the position within a string where the wrong character was encountered
	 *
	 * @dev Throws if input string contains a number bigger than uint256
	 *
	 * @param a numeric string to convert
	 * @param offset an index to start parsing from, set to zero to parse from the beginning
	 * @return i a number representing given string
	 * @return p an index where the conversion stopped
	 */
	function atoi(bytes calldata a, uint8 offset) internal pure returns (uint256 i, uint8 p) {
		// skip wrong characters in the beginning of the string if any
		for(p = offset; p < a.length; p++) {
			// check if digit is valid and meets the base 10
			if(isDecimal(a[p])) {
				// we've found decimal character, skipping stops
				break;
			}
		}

		// if there weren't any digits found
		if(p == a.length) {
			// just return a zero result
			return (0, offset);
		}

		// iterate over the rest of the string (bytes buffer)
		for(; p < a.length; p++) {
			// check if digit is valid and meets the base 10
			if(!isDecimal(a[p])) {
				// we've found bad character, parsing stops
				break;
			}

			// move to the next digit slot
			i *= 10;

			// extract the digit and add it to the result
			i += uint8(a[p]) - 0x30;
		}

		// return the result
		return (i, p);
	}

	/**
	 * @dev Checks if the byte1 represented character is a decimal number or not (base 10)
	 *
	 * @return true if the character represents a decimal number
	 */
	function isDecimal(bytes1 char) private pure returns (bool) {
		return uint8(char) >= 0x30 && uint8(char) < 0x3A;
	}

	/**
	 * @dev Parses a bytes string formatted as `{tokenId}:{metadata}`, containing `tokenId`
	 *      and `metadata` encoded as decimal strings
	 *
	 * @dev Throws if either `tokenId` or `metadata` strings are numbers bigger than uint256
	 * @dev Doesn't validate the `{tokenId}:{metadata}` format, would extract any first 2 decimal
	 *      numbers split with any separator, for example (see also land_blob_lib_test.js):
	 *      `{123}:{467}` => (123, 467)
	 *      `123:467` => (123, 467)
	 *      `123{}467` => (123, 467)
	 *      `b123abc467a` => (123, 467)
	 *      `b123abc467a8910` => (123, 467)
	 *      ` 123 467 ` => (123, 467)
	 *      `123\n467` => (123, 467)
	 *      `[123,467]` => (123, 467)
	 *      `[123; 467]` => (123, 467)
	 *      `(123, 467)` => (123, 467)
	 *      `(123, 467, 8910)` => (123, 467)
	 *      `{123.467}` => (123, 467)
	 *      `{123.467.8910}` => (123, 467)
	 *      `123` => (123, 0)
	 *      `abc123` => (123, 0)
	 *      `123abc` => (123, 0)
	 *      `{123}` => (123, 0)
	 *      `{123:}` => (123, 0)
	 *      `{:123}` => (123, 0)
	 *      `{,123}` => (123, 0)
	 *      `\n123` => (123, 0)
	 *      `{123,\n}` => (123, 0)
	 *      `{\n,123}` => (123, 0)
	 *      `(123, 0)` => (123, 0)
	 *      `0:123` => (0, 123)
	 *      `0:123:467` => (0, 123)
	 *      `0; 123` => (0, 123)
	 *      `(0, 123)` => (0, 123)
	 *      `(0, 123, 467)` => (0, 123)
	 *      `0,123` => (0, 123)
	 *      `0,123,467` => (0, 123)
	 *      `0.123` => (0, 123)
	 *      `0.123.467` => (0, 123)
	 *      `` => throws (no tokenId found)
	 *      `abc` => throws (no tokenId found)
	 *      `{}` => throws (no tokenId found)
	 *      `0` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *      `{0}` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *      `{0}:{0}` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *      `{0}:` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *      `(0, 0, 123)` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *      `:0` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *      `\n0` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *      `\n0\n0\n123` => (0, 0) - note: doesn't throw, even though zero tokenId is not valid
	 *
	 * @param mintingBlob bytes string input formatted as `{tokenId}:{metadata}`
	 * @return tokenId extracted `tokenId` as an integer
	 * @return metadata extracted `metadata` as an integer
	 */
	function parseMintingBlob(bytes calldata mintingBlob) internal pure returns (uint256 tokenId, uint256 metadata) {
		// indexes where the string parsing stops (where `atoi` reaches the "}")
		uint8 p1;
		uint8 p2;

		// read the `tokenId` value
		(tokenId, p1) = atoi(mintingBlob, 0);

		// ensure the parsed string has the `tokenId` value set
		require(p1 > 0, "no tokenId found");

		// read the `metadata` value
		(metadata, p2) = atoi(mintingBlob, p1);

		// return the result
		return (tokenId, metadata);
	}
}
