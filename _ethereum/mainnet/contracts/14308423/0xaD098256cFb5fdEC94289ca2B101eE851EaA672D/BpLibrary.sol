// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./SafeMathUpgradeable.sol";

library BpLibrary {
    using SafeMathUpgradeable for uint;

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}
