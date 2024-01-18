pragma solidity ^0.8.0;

import "./SortitionSumTreeFactory.sol";



contract TestSortitionTree {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees; // Use library functions for sortition sum trees.
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees; // The sortition sum trees.

    bytes32 treeKey;
    uint256 treeLeaves;
    uint256 public currentRandomNumber;

    constructor() {
        treeKey = keccak256(abi.encodePacked("treeKey"));
        treeLeaves = 4;
        currentRandomNumber = 4;
    
        sortitionSumTrees.createTree(treeKey, treeLeaves); // Create a tree with 4 children per node.
    }

    function setStake(uint256 _value, address user) public {
        bytes32 _ID = bytes32(uint256(uint160(user)));
        sortitionSumTrees.set(treeKey, _value, _ID);
    }

    function getStake(address user) public view returns (uint256) {
        bytes32 _ID = bytes32(uint256(uint160(user)));
        return sortitionSumTrees.stakeOf(treeKey, _ID);
    }

    function draw(uint256 _drawnNumber) public view returns (bytes32) {
        return sortitionSumTrees.draw(treeKey, uint(keccak256(abi.encodePacked(currentRandomNumber, _drawnNumber, block.timestamp))));
    }
}