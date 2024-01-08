// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract TheModZSecurity is Ownable {

    bool public isProvenanceLocked;

    uint public unlockTimestamp = 1635462000;
    uint public startingIndex;
    string public PROVENANCE;


    function lockProvenance() external onlyOwner {
        isProvenanceLocked = true;
    }

    function setUnlockTimestamp(uint _unlockTimestamp) external onlyOwner {
        unlockTimestamp = _unlockTimestamp;
    }

    function setProvenance(string memory provenance) external onlyOwner {
        require(!isProvenanceLocked, "PROVENANCE locked");
        PROVENANCE = provenance;
    }

    function setStartingIndex() external {
        require(startingIndex == 0, "Starting index already set");
        require(block.timestamp >= unlockTimestamp, "Contract is locked");
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.number,
                    blockhash(block.number - 1)
                )
            )
        );
        startingIndex = random % 5555 + 1;
    }
}