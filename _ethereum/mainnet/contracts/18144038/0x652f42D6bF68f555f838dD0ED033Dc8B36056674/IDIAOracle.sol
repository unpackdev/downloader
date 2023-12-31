// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
interface IDIAOracle{
    function setValue(string memory key, uint64 value0, uint64 value1, uint64 value2, uint64 value3, uint64 value4, uint64 timestamp) external;
    function getValue(string memory key) external view returns (uint64, uint64, uint64, uint64, uint64, uint64);

}