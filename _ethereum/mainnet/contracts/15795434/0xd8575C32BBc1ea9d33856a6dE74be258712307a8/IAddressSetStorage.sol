pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IAddressSetStorage {
    function getCount(bytes32 _key) external view returns (uint256);
    function getItem(bytes32 _key, uint256 _index) external view returns (address);
    function getIndexOf(bytes32 _key, address _value) external view returns (int256);
    function addItem(bytes32 _key, address _value) external;
    function removeItem(bytes32 _key, address _value) external;
}
