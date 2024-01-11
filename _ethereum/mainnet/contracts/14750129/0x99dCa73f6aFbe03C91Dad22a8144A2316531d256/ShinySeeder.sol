// SPDX-License-Identifier: GPL-3.0

/// @title The ShinyToken pseudo-random seed generator

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import "./IShinySeeder.sol";
import "./IShinyDescriptor.sol";

contract ShinySeeder is IShinySeeder {
    /**
     * @notice Generate a pseudo-random Shiny seed using the previous blockhash and Shiny ID.
     */
    // prettier-ignore
    function generateSeedForMint(uint256 shinyId, IShinyDescriptor descriptor, bool isShiny) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), shinyId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 eyesCount = descriptor.eyesCount();
        uint256 nosesCount = descriptor.nosesCount();
        uint256 mouthsCount = descriptor.mouthsCount();

        return Seed({
            background: uint16(
                uint16(pseudorandomness) % backgroundCount
            ),
            body: uint16(
                uint16(pseudorandomness >> 32) % bodyCount
            ),
            accessory: uint16(
                uint16(pseudorandomness >> 64) % accessoryCount
            ),
            head: uint16(
                uint16(pseudorandomness >> 96) % headCount
            ),
            eyes: uint16(
                uint16(pseudorandomness >> 128) % eyesCount
            ),
            nose: uint16(
                uint16(pseudorandomness >> 160) % nosesCount
            ),
            mouth: uint16(
                uint16(pseudorandomness >> 192) % mouthsCount
            ),
            shinyAccessory: isShiny ? uint16(1) : uint16(0)
        });
    }

        /**
     * @notice Generate a pseudo-random Shiny seed using the previous blockhash and Shiny ID.
     */
    // prettier-ignore
    function generateSeedWithValues(Seed memory newSeed,
                                    IShinyDescriptor descriptor,
                                    bool _isShiny) external view returns (Seed memory) {
        // Check that seedString values are valid
        require(newSeed.background <= descriptor.backgroundCount());
        require(newSeed.body <= descriptor.bodyCount());
        require(newSeed.accessory <= descriptor.accessoryCount());
        require(newSeed.head <= descriptor.headCount());
        require(newSeed.eyes <= descriptor.eyesCount());
        require(newSeed.nose <= descriptor.nosesCount());
        require(newSeed.mouth <= descriptor.mouthsCount());
        require(newSeed.shinyAccessory <= descriptor.shinyAccessoriesCount());
        // If not shiny, don't allow setting shinyAccessory
        if (!_isShiny) {
            require(newSeed.shinyAccessory == 0, 'Non-shiny is not allowed to change shinyAccessory');
        }

        return Seed({
            background: newSeed.background,
            body: newSeed.body,
            accessory: newSeed.accessory,
            head: newSeed.head,
            eyes: newSeed.eyes,
            nose: newSeed.nose,
            mouth: newSeed.mouth,
            shinyAccessory: newSeed.shinyAccessory
        });
    }
}
