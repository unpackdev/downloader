// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.22;

function uncheckedInc(uint256 i) pure returns (uint256) {
    unchecked {
        return i + 1;
    }
}
