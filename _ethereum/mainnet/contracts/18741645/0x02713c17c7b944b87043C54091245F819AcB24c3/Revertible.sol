// SPDX-License-Identifier: MIT
// Powered by Agora

pragma solidity 0.8.21;

abstract contract Revertible {
    function Revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
