// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

library HashLib {
	/**
	 * Keccak256 all parameters together
	 * @param a bytes32
	 */
	function hash1(bytes32 a) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			_hash := keccak256(0x00, 0x20)
		}
	}

	function hash1(address a) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			_hash := keccak256(0x00, 0x20)
		}
	}

	function hash2(bytes32 a, bytes32 b) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			mstore(0x20, b)
			_hash := keccak256(0x00, 0x40)
		}
	}

	function hash2(bytes32 a, address b) internal pure returns (bytes32 _hash) {
		bytes20 _b = bytes20(b);
		assembly {
			mstore(0x0, a)
			mstore(0x20, _b)
			_hash := keccak256(0x00, 0x34)
		}
	}

	function hash2(address a, address b) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes20 _b = bytes20(b);
		assembly {
			mstore(0x0, _a)
			mstore(0x14, _b)
			_hash := keccak256(0x00, 0x28)
		}
	}

	function hash2(address a, uint8 b) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes1 _b = bytes1(b);

		assembly {
			mstore(0x0, _b)
			mstore(0x1, _a)
			_hash := keccak256(0x00, 0x15)
		}
	}

	function hash2(bytes32 a, uint8 b) internal pure returns (bytes32 _hash) {
		bytes1 _b = bytes1(b);
		assembly {
			mstore(0x0, _b)
			mstore(0x1, a)
			_hash := keccak256(0x00, 0x21)
		}
	}

	function hash3(address a, address b, uint8 c) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes20 _b = bytes20(b);
		bytes1 _c = bytes1(c);
		assembly {
			mstore(0x00, _c)
			mstore(0x01, _a)
			mstore(0x15, _b)
			_hash := keccak256(0x00, 0x29)
		}
	}
}
