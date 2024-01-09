// SPDX-License-Identifier: GPL-3.0

/// @title The WizardsToken pseudo-random seed generator.
// Modified version from NounsDAO.

pragma solidity ^0.8.6;

import "./ISeeder.sol";
import "./IDescriptor.sol";

contract Seeder is ISeeder {
    struct Counts {
        uint256 backgroundCount;
        uint256 skinsCount;
        uint256 mouthsCount;
        uint256 eyesCount;
        uint256 hatsCount;
        uint256 clothesCount;
        uint256 accessoryCount;
        uint256 bgItemCount;
    }

    /**
     * @notice Generate a pseudo-random Wizard seed using the previous blockhash and wizard ID.
     */
    function generateSeed(
        uint256 wizardId,
        IDescriptor descriptor,
        bool isOneOfOne,
        uint48 oneOfOneIndex
    ) external view override returns (Seed memory) {
        if (isOneOfOne) {
            return
                Seed({
                    background: 0,
                    skin: 0,
                    bgItem: 0,
                    accessory: 0,
                    clothes: 0,
                    mouth: 0,
                    eyes: 0,
                    hat: 0,
                    oneOfOne: isOneOfOne,
                    oneOfOneIndex: oneOfOneIndex
                });
        }

        uint256 pseudorandomness = getRandomness(wizardId);
        Counts memory counts = getCounts(descriptor);
        uint256 accShift = getAccShift(wizardId);
        uint256 clothShift = getClothShift(wizardId);

        return
            Seed({
                background: uint48(
                    uint48(pseudorandomness) % counts.backgroundCount
                ),
                skin: uint48(
                    uint48(pseudorandomness >> 48) % counts.skinsCount
                ),
                accessory: uint48(
                    uint48(pseudorandomness >> accShift) % counts.accessoryCount
                ),
                mouth: uint48(
                    uint48(pseudorandomness >> 144) % counts.mouthsCount
                ),
                eyes: uint48(
                    uint48(pseudorandomness >> 192) % counts.eyesCount
                ),
                hat: uint48(uint48(pseudorandomness >> 144) % counts.hatsCount),
                bgItem: uint48(
                    uint48(pseudorandomness >> accShift) % counts.bgItemCount
                ),
                clothes: uint48(
                    uint48(pseudorandomness >> clothShift) % counts.clothesCount
                ),
                oneOfOne: isOneOfOne,
                oneOfOneIndex: oneOfOneIndex
            });
    }

    function getCounts(IDescriptor descriptor)
        internal
        view
        returns (Counts memory)
    {
        return
            Counts({
                backgroundCount: descriptor.backgroundCount(),
                skinsCount: descriptor.skinsCount(),
                mouthsCount: descriptor.mouthsCount(),
                eyesCount: descriptor.eyesCount(),
                hatsCount: descriptor.hatsCount(),
                clothesCount: descriptor.clothesCount(),
                accessoryCount: descriptor.accessoryCount(),
                bgItemCount: descriptor.bgItemsCount()
            });
    }

    function getRandomness(uint256 wizardId) internal view returns (uint256) {
        uint256 pseudorandomness = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    wizardId,
                    block.difficulty,
                    block.coinbase
                )
            )
        );

        return pseudorandomness;
    }

    function getAccShift(uint256 wizardId) internal pure returns (uint256) {
        uint256 rem = wizardId % 2;
        uint256 shift = (rem == 0) ? 96 : 192;

        return shift;
    }

    function getClothShift(uint256 wizardId) internal pure returns (uint256) {
        uint256 rem = wizardId % 2;
        uint256 clothShift = (rem == 0) ? 48 : 144;

        return clothShift;
    }
}
