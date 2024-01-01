// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./IMedian.sol";
import "./Ownable.sol";

contract ChronicleMedianSourceMock is IMedian, Ownable {
    uint256 public value;
    uint32 public ageValue;

    function age() external view returns (uint32) {
        return ageValue;
    }

    function read() external view returns (uint256) {
        return value;
    }

    function peek() external view returns (uint256, bool) {
        return (value, true);
    }

    function setLatestSourceData(uint256 _value, uint32 _age) public onlyOwner {
        value = _value;
        ageValue = _age;
    }

    function kiss(address) external override {}
}
