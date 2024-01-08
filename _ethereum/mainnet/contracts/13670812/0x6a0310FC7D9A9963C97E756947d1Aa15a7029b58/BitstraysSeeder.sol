// SPDX-License-Identifier: GPL-3.0

/// @title The BitstraysToken pseudo-random seed generator

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@........................@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%.................................@@@@@@@@@@@@@
.......................@@@@@@@..............................
./@@@@@@@@@...................@@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@.......@@@@@.........@@@.........@@@@@.......@@@@@.
@%..@@.......................................@@.......@@@..@
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@...@@@@#  @@   @@   .........  ,@@  @@@  .......@@@@@@
@@@@@@.....@@#  @@@@@@@   .........  ,@@@@@@@  .......@@@@@@
@@@@@@.....@@@@@       @@%............       .........@@@@@@
@@@@@@@@@..../@@@@@@@@@.............................@@@@@@@@
@@@@@@@@@............                   ............@@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  .....@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import "./IBitstraysSeeder.sol";
import "./IBitstraysDescriptor.sol";

contract BitstraysSeeder is IBitstraysSeeder {
    /**
     * @notice Generate a pseudo-random Bitstray seed using the previous blockhash and bitstray ID.
     */
    // prettier-ignore
    function generateSeed(uint256 bitstrayId, IBitstraysDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), bitstrayId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 armsCount = descriptor.armsCount();
        uint256 shirtsCount = descriptor.shirtsCount();
        uint256 motivesCount = descriptor.motivesCount();
        uint256 headCount = descriptor.headCount();
        uint256 eyesCount = descriptor.eyesCount();
        uint256 mouthsCount = descriptor.mouthsCount();

        uint256 kings = 10; //number of king hads
        uint256 beanies = 26; //number of special heads

        uint48 rarity = uint48(uint48(pseudorandomness) % 100);

        if (rarity < 75) { //normal
            headCount = headCount-beanies-kings;
        } else if ( rarity > 75 && rarity < 90 ) {
            headCount = headCount-kings; //add special head
        }

        return Seed({
            background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
            arms: uint48(
                uint48(pseudorandomness >> 240) % armsCount
            ),
            shirt: uint48(
                uint48(pseudorandomness >> 24) % shirtsCount
            ),
            motive: uint48(
                uint48(pseudorandomness >> 48) % motivesCount
            ),
            head: uint48(
                uint48(pseudorandomness >> 96) % headCount
            ),
            eyes: uint48(
                uint48(pseudorandomness >> 144) % eyesCount
            ),
            mouth: uint48(
                uint48(pseudorandomness >> 192) % mouthsCount
            )
        });
    }
}
