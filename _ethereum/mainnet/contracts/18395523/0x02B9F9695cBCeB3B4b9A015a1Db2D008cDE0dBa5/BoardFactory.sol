pragma solidity ^0.8.0;

import "./Strings.sol";

contract BoardFactory {

    function generateBoard(uint _tokenId) internal view returns (uint256) {
        uint256 packedNumbers = 0;
        uint8[] memory availableNumbers = new uint8[](15);
        for (uint8 i = 0; i < 5; i++) {
            for (uint8 j = 0; j < 15; j++) {
                availableNumbers[j] = j + 1;
            }
            uint8 availableCount = 15;
            if (i == 2) {
                availableCount--;
            }
            for (uint8 j = 0; j < 5; j++) {
                uint8 chosenNumber;
                if (i == 2 && j == 2) {
                    chosenNumber = 0;
                } else {
                    uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, i, j)));
                    uint8 chosenIndex = uint8(randomNumber % availableCount);
                    chosenNumber = availableNumbers[chosenIndex];
                    availableNumbers[chosenIndex] = availableNumbers[availableCount - 1];
                    availableCount--;
                }
                uint8 offset = 4 * (5 * i + j);
                uint256 packedNumber = uint256(chosenNumber) << offset;
                packedNumbers |= packedNumber;
            }
        }
        return packedNumbers;
    }

    function unpackNumbers(uint packedNumbers) internal pure returns (uint8[5][5] memory) {
        uint8[5][5] memory numbers;
        
        for (uint8 i = 0; i < 5; i++) {
            for (uint8 j = 0; j < 5; j++) {
                uint8 offset = uint8(i * 20 + j * 4);
                uint8 number = uint8((packedNumbers >> offset) & 15);
                numbers[j][i] = (i == 2 && j == 2) ? 0 : i * 15 + number;
            }
        }
        return numbers;
    }

    function unpackToString(uint256 packedNumbers) internal pure returns (string memory) {
        string memory result = "";
        for (uint i = 0; i < 25; i++) {
            uint8 number = (i == 12) ? 0 : uint8((packedNumbers >> (i * 4)) & 0xF) + uint8(i / 5 * 15);
            result = string(abi.encodePacked(result, Strings.toString(number)));
            if (i != 24) {
                result = string(abi.encodePacked(result, ","));
            }
        }
        return result;
    }

    function getNumberByCoordinates(uint8 x, uint8 y, uint256 packedNumbers) internal pure returns (uint8) {
        require(x < 5 && y < 5, "Invalid coordinates");
        uint8 index = y * 5 + x;
        uint8 number = uint8((packedNumbers >> (index * 4)) & 0xF);
        return number;
    }

}