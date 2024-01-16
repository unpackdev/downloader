// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library metalib {
    function moods(
        uint256 mood
    ) internal pure returns (string memory) {
        if (mood == 1) {return "Emotional elevation";}
        else if (mood == 2) {return "Members only";}
        else if (mood == 3) {return "RAMBO";}
        else if (mood == 4) {return "Temper";}
        else if (mood == 5) {return "sensitive";}
        else if (mood == 6) {return "Final boss";}
        else if (mood == 7) {return "cypherpunk";}
        else if (mood == 8) {return "distant memory";}
        else if (mood == 9) {return "High-end system";}
        else if (mood == 10) {return "Forgive and forget";}
        else if (mood == 11) {return "Rising star";}
        else if (mood == 12) {return "Special agent";}
        else if (mood == 13) {return "Wonderful sight";}
        else if (mood == 14) {return "Hello world!";}
        else if (mood == 15) {return "Super star";}
        else if (mood == 16) {return "Five stars";}
        else if (mood == 17) {return "Sign of god";}
        else if (mood == 18) {return "run";}
        else if (mood == 19) {return "Don't trend on me";}
        else if (mood == 20) {return "Simulated experience";}
        else {return "After party";}
    }

    function grades(
        uint256 grade
    ) internal pure returns (string memory) {
        if (grade == 1) {return "AI";}
        else if (grade == 2) {return "5";}
        else if (grade == 3) {return "V";}
        else if (grade == 4) {return "GMO";}
        else if (grade == 5) {return "XXX";}
        else {return "Z";}
    }
}
