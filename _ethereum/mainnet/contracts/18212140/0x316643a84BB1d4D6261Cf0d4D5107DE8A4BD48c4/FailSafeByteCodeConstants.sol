// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BeaconProxy.sol";

contract FailSafeByteCodeConstants {
    function getBeaconCode() external pure returns (bytes memory) {
        return type(BeaconProxy).creationCode;
    }
}