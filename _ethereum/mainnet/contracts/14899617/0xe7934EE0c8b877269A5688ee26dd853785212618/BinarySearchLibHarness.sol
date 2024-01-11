// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "./BinarySearchLib.sol";

contract BinarySearchLibHarness {
    using BinarySearchLib for uint32[];
    uint32[] internal history;

    function getIndex(uint32 id) external view returns (uint32)
    {
        return history.binarySearch(id);
    }
    
    function getIndexes(uint32[] calldata ids) external view returns (uint32[] memory)
    {
        uint32[] memory data = new uint32[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            data[i] = history.binarySearch(ids[i]);
        }
        return data;
    }

    function set(uint32[] calldata _history) external
    {
        history = _history;
    }
}
