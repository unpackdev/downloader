// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "./Concat.sol";

library RevertMsg {
    using Concat for string;
    function ToString(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return string(" - ").concat(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}