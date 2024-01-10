// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";

interface IStateManager is ILazyInitCapableElement {

    struct StateEntry {
        string key;
        bytes32 entryType;
        bytes value;
    }

    function size() external view returns (uint256);
    function all() external view returns (StateEntry[] memory);
    function partialList(uint256 start, uint256 offset) external view returns (StateEntry[] memory);
    function list(string[] calldata keys) external view returns (StateEntry[] memory);
    function listByIndices(uint256[] calldata indices) external view returns (StateEntry[] memory);

    function exists(string calldata key) external view returns(bool result, uint256 index);

    function get(string calldata key) external view returns(StateEntry memory);
    function getByIndex(uint256 index) external view returns(StateEntry memory);

    function set(StateEntry calldata newValue) external returns(bytes memory replacedValue);
    function batchSet(StateEntry[] calldata newValues) external returns(bytes[] memory replacedValues);

    function remove(string calldata key) external returns(bytes32 removedType, bytes memory removedValue);
    function batchRemove(string[] calldata keys) external returns(bytes32[] memory removedTypes, bytes[] memory removedValues);
    function removeByIndices(uint256[] calldata indices) external returns(bytes32[] memory removedTypes, bytes[] memory removedValues);
}