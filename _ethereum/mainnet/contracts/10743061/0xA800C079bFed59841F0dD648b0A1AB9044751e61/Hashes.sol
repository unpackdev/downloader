pragma solidity ^0.7.0;

// "SPDX-License-Identifier: UNLICENSED"

contract Hashes {
    event HashAdded(address indexed sender, bytes32 hash, uint256 blockNumber);

    mapping (bytes32 => uint256) private hashes;
    
    function addHash (bytes32 _hash) public {
        require(hashes[_hash] == 0, "The hash was already added");
        
        hashes[_hash] = block.number;
        
        emit HashAdded(msg.sender, _hash, block.number);
    }
    
    function findHash (bytes32 _hash) public view returns(uint) {
        return hashes[_hash];
    }
}