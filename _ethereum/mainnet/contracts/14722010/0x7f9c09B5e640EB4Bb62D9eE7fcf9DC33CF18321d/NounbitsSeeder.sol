// SPDX-License-Identifier: GPL-3.0

/// @title The NounsToken pseudo-random seed generator

pragma solidity ^0.8.6;

import "./INounsSeeder.sol";
import "./INounsDescriptor.sol";

contract NounbitsSeeder is INounsSeeder {
    /**
     * @notice Generate a pseudo-random Noun seed using a pseudorandom blockhash and noun ID.
     */
    // prettier-ignore
    function generateSeed(uint256 nounId, INounsDescriptor descriptor, bytes32 pseudorandomHash) external view override returns (Seed memory) {
        if (pseudorandomHash == 0) {
            return Seed({background: 0, body: 0, accessory: 0, head: 0, glasses: 0, pants: 0, shoes: 0});
        }

        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(pseudorandomHash, nounId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 glassesCount = descriptor.glassesCount();
        uint256 pantsCount = descriptor.pantCount();
        uint256 shoesCount = descriptor.shoeCount();

        return Seed({
            background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
            body: uint48(
                uint48(pseudorandomness >> 32) % bodyCount
            ),
            accessory: uint48(
                uint48(pseudorandomness >> 64) % accessoryCount
            ),
            head: uint48(
                uint48(pseudorandomness >> 96) % headCount
            ),
            glasses: uint48(
                uint48(pseudorandomness >> 128) % glassesCount
            ),
            pants: uint48(
                uint48(pseudorandomness >> 160) % pantsCount
            ),
            shoes: uint48(
                uint48(pseudorandomness >> 192) % shoesCount
            )
        });
    }
}