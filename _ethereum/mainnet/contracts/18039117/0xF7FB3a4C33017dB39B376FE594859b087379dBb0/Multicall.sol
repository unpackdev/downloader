// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract Multicall {
    function multicall(bytes[] calldata _data) external returns (bytes[] memory results) {
        uint256 length = _data.length;
        results = new bytes[](length);

        bool success;
        for (uint256 i; i < length; ) {
            bytes memory result;
            (success, result) = address(this).delegatecall(_data[i]);
            if (!success) {
                if (result.length == 0) revert();
                _revertedWithReason(result);
            }

            results[i] = result;
            unchecked {
                ++i;
            }
        }
    }

    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}
