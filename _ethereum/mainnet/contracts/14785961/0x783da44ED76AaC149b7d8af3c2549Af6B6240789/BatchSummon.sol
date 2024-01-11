// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8;

import "./Ownable.sol";

interface ISummon {
    function mintFighter() external;

    function mintFighters(uint256 count) external;
}

interface IFighter {
    function mintBatch(address[] calldata to, uint256[] calldata counts)
        external;
}

// https://cs.opensource.google/go/go/+/master:src/math/rand/rand.go;l=5;drc=690ac4071fa3e07113bf371c9e74394ab54d6749
contract BatchSummon is Ownable {
    ISummon public summon;
    bool summonSupportsBatchSummon;

    constructor(address summonContract) {
        summon = ISummon(summonContract);
    }

    function setSummon(address summonContract, bool supportsBatch)
        external
        onlyOwner
    {
        summon = ISummon(summonContract);
        summonSupportsBatchSummon = supportsBatch;
    }

    function mintFightersSequentially(uint256 count) external {
        unchecked {
            for (uint256 i; i < count; i++) {
                summon.mintFighter();
            }
        }
    }

    function mintFighters(uint256 count) external {
        require(summonSupportsBatchSummon, "Not supported by the contract");
        summon.mintFighters(count);
    }
}
