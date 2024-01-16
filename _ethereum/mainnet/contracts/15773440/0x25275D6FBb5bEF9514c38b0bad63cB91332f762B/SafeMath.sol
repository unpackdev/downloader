// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

/**
 * Standard signed math utilities missing in the Solidity language.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * it means: 100*2‱ = 100*2/10000
     */
    function rate(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, b), 10000);
    }
}
