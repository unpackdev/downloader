// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Import contract UUPS
import "./Box.sol";

contract BoxV2 is Box {
    uint256 private _value;

    function setValue(uint256 value) public {
        _value = value;
    }

    function getValueSquared() public view returns (uint256) {
        return _value * _value;
    }
}
