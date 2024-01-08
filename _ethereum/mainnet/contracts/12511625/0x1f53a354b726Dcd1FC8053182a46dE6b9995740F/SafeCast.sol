// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

// See https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/SafeCast.sol
library SafeCast {
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}
