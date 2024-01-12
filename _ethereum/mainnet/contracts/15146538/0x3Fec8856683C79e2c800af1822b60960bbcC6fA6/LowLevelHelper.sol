// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

library LowLevelHelper {
    function patchFirstUint(bytes calldata data, uint256 value)
        internal
        pure
        returns (bytes memory result)
    {
        result = data;
        assembly {
            // 36 bytes offset: selector (4) + length (32)
            mstore(add(result, 36), value)
        }
    }
}
