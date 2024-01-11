// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IRandomizer.sol";

contract Randomizer is IRandomizer, Ownable {
    mapping(address => bool) public dependencies;

    function addDependency(address _dependency) public onlyOwner {
        dependencies[_dependency] = true;
    }

    function removeDependency(address _dependency) public onlyOwner {
        dependencies[_dependency] = false;
    }

    function getRandomValue() external view onlyDependency returns (uint256) {
        return uint256(blockhash(block.number - 1)) + 369963;
    }

    modifier onlyDependency() {
        require(dependencies[msg.sender], "Caller is not in dependency list");
        _;
    }
}
