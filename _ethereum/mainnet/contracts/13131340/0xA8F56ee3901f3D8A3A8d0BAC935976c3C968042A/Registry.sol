// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Utils.sol";

contract Registry {

    
    mapping(bytes32=>string) registry;
    bytes32[] private index;

    constructor(){
    
    }

    function count() public view returns(uint256){
        return index.length;
    }

    function atIndex(uint256 _i) public view returns(string memory){
        
        return registry[index[_i]];
    }

    function discover(string memory _name) public returns(bytes32){
        if(bytes(_name).length == 0){
          revert("Revert due to empty name");
        }
        bytes32 hash = Utils.hashString(_name);
        if(bytes(registry[hash]).length == 0){
            registry[hash] = _name;
        }
        return hash;
    }
    function reveal(bytes32 hash) public view returns(string memory){
        return registry[hash];
    }

    function isDiscovered(string memory _name) public view returns(bool) {
        bytes32 hash = Utils.hashString(_name);
        return bytes(registry[hash]).length > 0;
    }

}
