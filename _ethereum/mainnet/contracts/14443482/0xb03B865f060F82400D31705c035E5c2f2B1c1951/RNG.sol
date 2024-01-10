// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

library RNG {
    struct Data {
        uint256 seed;
        uint256 i;
    }

    function rand(Data memory rng) internal pure returns (uint256) {
        unchecked {
            return uint256(keccak256(abi.encode(rng.seed, rng.i++)));
        }
    }
}
