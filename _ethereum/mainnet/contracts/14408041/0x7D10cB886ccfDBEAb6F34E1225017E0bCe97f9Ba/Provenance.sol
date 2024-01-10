// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;


contract Provenance {

    // Provenance hash for metadata.
    bytes32 public provenance;
    uint256 public startingIndex;
    uint256 public startingIndexBlock;
    uint256 public revealTimestamp;


    /* ------------------------------ Internal Methods ----------------------------- */

    function _setProvenance(bytes32 provenanceHash) internal {
        provenance = provenanceHash;
    }

    function _setRevealTime(uint256 timestamp) internal {
        revealTimestamp = timestamp;
    }

    function _finalizeStartingIndex(uint256 maxSupply) internal {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = (uint(blockhash(startingIndexBlock)) % maxSupply) + 1;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = (uint(blockhash(block.number-1)) % maxSupply) + 1;
        }
        // Prevent default sequence
        if (startingIndex == 1) {
            startingIndex = startingIndex + 1;
        }
    }

    function _setStartingBlock(uint256 currentCount, uint256 maxSupply) internal {
        /**
         * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
         */
        if (startingIndexBlock == 0 && (currentCount == maxSupply || block.timestamp >= revealTimestamp)) {
            startingIndexBlock = block.number;
        }
    }

}