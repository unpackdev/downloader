// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./LibPRNG.sol";

contract seedGenerator {
    using LibPRNG for *;

    function createTokenChar(
        uint256 n
    ) internal view returns (uint256 encoded) {
        ///this was part of smolMoney before - now as own function

        LibPRNG.PRNG memory prng;

        uint256 seed = uint256(blockhash(block.number - 1)) + n;
        prng.seed(seed);
        uint256 r0 = prng.uniform(120); //main char
        uint256 r1 = prng.uniform(10); //second char
        uint256 r2 = prng.uniform(21); //third char
        uint256 r3 = prng.uniform(1891); //character

        uint256 r4 = prng.uniform(300); //body
        uint256 r5 = prng.uniform(28); //animation - note: this produces values from 0 - 27
        uint256 r6 = prng.uniform(14); //backgroundcolor
        uint256 r7 = prng.uniform(104); //fontcolor
        uint256 r8 = prng.uniform(10); //reverse color

        ///diffrent format encoding - its all just one uint256
        //887766554433221199
        //               11 = first char    (#,+,:,▆,▒▒, etc)  00 - 04
        //               22 = second char   (*,',~,etc)        00 - 02
        //               33 = third char    (=,-,>,<,#,/,etc)  00 - 05
        //               44 = character     00 - 23
        //               55 = body           00 - 24
        //               66 = animation
        //               77 = backgroundcolor
        //               88 = fontcolor
        //               99 = filler

        encoded = 99;

        // codegen from here
        // first char
        if (r0 < 1) {
            encoded = encoded + 0;
        } else if (r0 < 3) {
            encoded = encoded + 100;
        } else if (r0 < 6) {
            encoded = encoded + 200;
        } else if (r0 < 10) {
            encoded = encoded + 300;
        } else if (r0 < 15) {
            encoded = encoded + 400;
        } else if (r0 < 21) {
            encoded = encoded + 500;
        } else if (r0 < 28) {
            encoded = encoded + 600;
        } else if (r0 < 36) {
            encoded = encoded + 700;
        } else if (r0 < 45) {
            encoded = encoded + 800;
        } else if (r0 < 55) {
            encoded = encoded + 900;
        } else if (r0 < 66) {
            encoded = encoded + 1000;
        } else if (r0 < 78) {
            encoded = encoded + 1100;
        } else if (r0 < 91) {
            encoded = encoded + 1200;
        } else if (r0 < 105) {
            encoded = encoded + 1300;
        } else if (r0 < 120) {
            encoded = encoded + 1400;
        }

        /// second char

        if (r1 < 1) {
            encoded = encoded + 0;
        } else if (r1 < 3) {
            encoded = encoded + 10000;
        } else if (r1 < 6) {
            encoded = encoded + 20000;
        } else if (r1 < 10) {
            encoded = encoded + 30000;
        }

        /// third char

        if (r2 < 1) {
            encoded = encoded + 0;
        } else if (r2 < 3) {
            encoded = encoded + 1000000;
        } else if (r2 < 6) {
            encoded = encoded + 2000000;
        } else if (r2 < 10) {
            encoded = encoded + 3000000;
        } else if (r2 < 15) {
            encoded = encoded + 4000000;
        } else if (r2 < 21) {
            encoded = encoded + 5000000;
        }

        /// character char
        if (r3 < 1) {
            encoded = encoded + 0;
        } else if (r3 < 3) {
            encoded = encoded + 100000000;
        } else if (r3 < 6) {
            encoded = encoded + 200000000;
        } else if (r3 < 10) {
            encoded = encoded + 300000000;
        } else if (r3 < 15) {
            encoded = encoded + 400000000;
        } else if (r3 < 21) {
            encoded = encoded + 500000000;
        } else if (r3 < 28) {
            encoded = encoded + 600000000;
        } else if (r3 < 36) {
            encoded = encoded + 700000000;
        } else if (r3 < 45) {
            encoded = encoded + 800000000;
        } else if (r3 < 55) {
            encoded = encoded + 900000000;
        } else if (r3 < 66) {
            encoded = encoded + 1000000000;
        } else if (r3 < 78) {
            encoded = encoded + 1100000000;
        } else if (r3 < 91) {
            encoded = encoded + 1200000000;
        } else if (r3 < 105) {
            encoded = encoded + 1300000000;
        } else if (r3 < 120) {
            encoded = encoded + 1400000000;
        } else if (r3 < 136) {
            encoded = encoded + 1500000000;
        } else if (r3 < 153) {
            encoded = encoded + 1600000000;
        } else if (r3 < 171) {
            encoded = encoded + 1700000000;
        } else if (r3 < 190) {
            encoded = encoded + 1800000000;
        } else if (r3 < 210) {
            encoded = encoded + 1900000000;
        } else if (r3 < 231) {
            encoded = encoded + 2000000000;
        } else if (r3 < 253) {
            encoded = encoded + 2100000000;
        } else if (r3 < 276) {
            encoded = encoded + 2200000000;
        } else if (r3 < 300) {
            encoded = encoded + 2300000000;
        } else if (r3 < 325) {
            encoded = encoded + 2400000000;
        } else if (r3 < 351) {
            encoded = encoded + 2500000000;
        } else if (r3 < 378) {
            encoded = encoded + 2600000000;
        } else if (r3 < 406) {
            encoded = encoded + 2700000000;
        } else if (r3 < 435) {
            encoded = encoded + 2800000000;
        } else if (r3 < 465) {
            encoded = encoded + 2900000000;
        } else if (r3 < 496) {
            encoded = encoded + 3000000000;
        } else if (r3 < 528) {
            encoded = encoded + 3100000000;
        } else if (r3 < 561) {
            encoded = encoded + 3200000000;
        } else if (r3 < 595) {
            encoded = encoded + 3300000000;
        } else if (r3 < 630) {
            encoded = encoded + 3400000000;
        } else if (r3 < 666) {
            encoded = encoded + 3500000000;
        } else if (r3 < 703) {
            encoded = encoded + 3600000000;
        } else if (r3 < 741) {
            encoded = encoded + 3700000000;
        } else if (r3 < 780) {
            encoded = encoded + 3800000000;
        } else if (r3 < 820) {
            encoded = encoded + 3900000000;
        } else if (r3 < 861) {
            encoded = encoded + 4000000000;
        } else if (r3 < 903) {
            encoded = encoded + 4100000000;
        } else if (r3 < 946) {
            encoded = encoded + 4200000000;
        } else if (r3 < 990) {
            encoded = encoded + 4300000000;
        } else if (r3 < 1035) {
            encoded = encoded + 4400000000;
        } else if (r3 < 1081) {
            encoded = encoded + 4500000000;
        } else if (r3 < 1128) {
            encoded = encoded + 4600000000;
        } else if (r3 < 1176) {
            encoded = encoded + 4700000000;
        } else if (r3 < 1225) {
            encoded = encoded + 4800000000;
        } else if (r3 < 1275) {
            encoded = encoded + 4900000000;
        } else if (r3 < 1326) {
            encoded = encoded + 5000000000;
        } else if (r3 < 1378) {
            encoded = encoded + 5100000000;
        } else if (r3 < 1431) {
            encoded = encoded + 5200000000;
        } else if (r3 < 1485) {
            encoded = encoded + 5300000000;
        } else if (r3 < 1540) {
            encoded = encoded + 5400000000;
        } else if (r3 < 1596) {
            encoded = encoded + 5500000000;
        } else if (r3 < 1653) {
            encoded = encoded + 5600000000;
        } else if (r3 < 1711) {
            encoded = encoded + 5700000000;
        } else if (r3 < 1770) {
            encoded = encoded + 5800000000;
        } else if (r3 < 1830) {
            encoded = encoded + 5900000000;
        } else if (r3 < 1891) {
            encoded = encoded + 6000000000;
        }

        //body
        if (r4 < 1) {
            encoded = encoded + 0;
        } else if (r4 < 3) {
            encoded = encoded + 10000000000;
        } else if (r4 < 6) {
            encoded = encoded + 20000000000;
        } else if (r4 < 10) {
            encoded = encoded + 30000000000;
        } else if (r4 < 15) {
            encoded = encoded + 40000000000;
        } else if (r4 < 21) {
            encoded = encoded + 50000000000;
        } else if (r4 < 28) {
            encoded = encoded + 60000000000;
        } else if (r4 < 36) {
            encoded = encoded + 70000000000;
        } else if (r4 < 45) {
            encoded = encoded + 80000000000;
        } else if (r4 < 55) {
            encoded = encoded + 90000000000;
        } else if (r4 < 66) {
            encoded = encoded + 100000000000;
        } else if (r4 < 78) {
            encoded = encoded + 110000000000;
        } else if (r4 < 91) {
            encoded = encoded + 120000000000;
        } else if (r4 < 105) {
            encoded = encoded + 130000000000;
        } else if (r4 < 120) {
            encoded = encoded + 140000000000;
        } else if (r4 < 136) {
            encoded = encoded + 150000000000;
        } else if (r4 < 153) {
            encoded = encoded + 160000000000;
        } else if (r4 < 171) {
            encoded = encoded + 170000000000;
        } else if (r4 < 190) {
            encoded = encoded + 180000000000;
        } else if (r4 < 210) {
            encoded = encoded + 190000000000;
        } else if (r4 < 231) {
            encoded = encoded + 200000000000;
        } else if (r4 < 253) {
            encoded = encoded + 210000000000;
        } else if (r4 < 276) {
            encoded = encoded + 220000000000;
        } else if (r4 < 300) {
            encoded = encoded + 230000000000;
        }

        if (r5 < 2) {
            encoded = encoded + 0;
        } else if (r5 < 4) {
            encoded = encoded + 1000000000000;
        } else if (r5 < 8) {
            encoded = encoded + 2000000000000;
        } else if (r5 < 14) {
            encoded = encoded + 3000000000000;
        } else if (r5 < 28) {
            encoded = encoded + 4000000000000;
        }
        ///background
        if (r6 < 2) {
            encoded = encoded + 0;
        } else if (r6 < 3) {
            encoded = encoded + 100000000000000;
        } else if (r6 < 6) {
            encoded = encoded + 200000000000000;
        } else if (r6 < 9) {
            encoded = encoded + 300000000000000;
        } else if (r6 < 15) {
            encoded = encoded + 400000000000000;
        }

        ///fontc

        if (r7 < 2) {
            encoded = encoded + 0;
        } else if (r7 < 5) {
            encoded = encoded + 10000000000000000;
        } else if (r7 < 12) {
            encoded = encoded + 20000000000000000;
        } else if (r7 < 20) {
            encoded = encoded + 30000000000000000;
        } else if (r7 < 29) {
            encoded = encoded + 40000000000000000;
        } else if (r7 < 39) {
            encoded = encoded + 50000000000000000;
        } else if (r7 < 50) {
            encoded = encoded + 60000000000000000;
        } else if (r7 < 62) {
            encoded = encoded + 70000000000000000;
        } else if (r7 < 75) {
            encoded = encoded + 80000000000000000;
        } else if (r7 < 89) {
            encoded = encoded + 90000000000000000;
        }

        // reverse colors
        if (r8 < 1) {
            encoded = encoded + 0;
        } else if (r8 < 11) {
            encoded = encoded + 1000000000000000000;
        }

        return encoded;
    }
}
