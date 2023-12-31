// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./LowLevelHelper.sol";

struct TestStruct {
    uint256 a;
    uint256 b;
}

contract LowLevelHelperMock {
    function patchUint(bytes calldata data, uint256 value, uint256 offset) public pure returns (bytes memory result) {
        return LowLevelHelper.patchUint(data, value, offset);
    }

    function testStructEncoding(TestStruct calldata x, TestStruct calldata y, TestStruct calldata z) external pure returns (uint256) {
        return x.a + x.b + y.a + y.b + z.a + z.b;
    }
}

contract TestExample {
    function alwaysReturnMinus57() external pure returns (int24) {
        return -57;
    }
}
