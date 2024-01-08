// SPDX-License-Identifier: GPL-3.0

/// @title The BitstraySantasToken pseudo-random seed generator

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

contract BitstraySantasSeeder is IBitstraysSeeder {

    // santa heads
    //uint256 [6] santaList = [98, 95, 94, 93, 91, 88];
    /**
     * @notice Generate a pseudo-random Bitstray seed using the previous blockhash and bitstray ID.
     */
    // prettier-ignore
    function generateSeed(uint256 bitstrayId, IBitstraysDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), bitstrayId))
        );
        // limit slection for christmas drop
        uint8[14] memory headsIndex = [98, 95, 94, 93, 91, 88, 87, 86, 84, 83, 79, 78, 76, 75];
        uint8[4] memory bgIndex = [1, 4, 5, 6];
        uint8[7] memory shirtIndex = [2, 3, 5 , 6 ,7 ,8 , 9];
        uint256 backgroundCount = bgIndex.length;
        uint256 armsCount = descriptor.armsCount();
        uint256 shirtsCount = shirtIndex.length;
        uint256 motivesCount = descriptor.motivesCount();
        uint256 headCount = headsIndex.length;
        uint256 eyesCount = descriptor.eyesCount();
        uint256 mouthsCount = descriptor.mouthsCount();

        return Seed({
            background: uint48(
                bgIndex[uint48(pseudorandomness) % backgroundCount]
            ),
            arms: uint48(
                uint48(pseudorandomness >> 240) % armsCount
            ),
            shirt: uint48(
                shirtIndex[uint48(pseudorandomness >> 24) % shirtsCount]
            ),
            motive: uint48(
                uint48(pseudorandomness >> 48) % motivesCount
            ),
            head: uint48(
                headsIndex[uint48(pseudorandomness >> 96) % headCount]
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
