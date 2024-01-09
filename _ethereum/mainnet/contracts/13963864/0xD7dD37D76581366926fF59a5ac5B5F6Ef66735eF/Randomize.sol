//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to get random number
library Randomize {
    struct Random {
        uint256 seed;
        uint256 nonce;
    }

    function next(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256 result) {
        max += 1;
        uint256 number = uint256(keccak256(abi.encode(random.seed,random.nonce))) % (max - min);
        random.nonce++;
        result = number + min;
    }
}