//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ICryptoBees.sol";
import "./Traits.sol";
import "./IAttack.sol";

contract Randomizer is Ownable {
    struct Commit {
        uint256 block;
        address sender;
    }

    mapping(uint256 => Commit) commits;
    mapping(address => bool) controllers;
    uint256 commitIndex;

    event CommitHash(address indexed sender, uint256 block, uint256 index);

    constructor() {}

    function createCommit() public {
        require(controllers[msg.sender], "Not permitted");
        commits[commitIndex].block = block.number;
        commits[commitIndex].sender = tx.origin;
        commitIndex += 1;
        emit CommitHash(tx.origin, block.number, commitIndex - 1);
    }

    function reset(uint256 to) public onlyOwner {
        commitIndex = to;
    }

    function revealSeed(uint256 i) public view returns (uint256) {
        if (i < commitIndex && block.number > commits[i].block) return uint256(keccak256(abi.encode(commits[i].sender, i, blockhash(commits[i].block))));
        return 0;
    }

    /**
     * enables an address
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}
