//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

/**
 * All of this encoding is assuming that we use a custom mapping of colors to use only 4 bits per pixel
 */

library SceneLib {
    uint256 constant bitsPerPixel = 4; // Best if divisor of 256, e.g., 2, 4, 8, 16, 32
    uint256 constant unitSize = 2**bitsPerPixel; // The number of colors we can handle
    uint256 constant encodingInWord = 256 / bitsPerPixel;
    uint256 constant wordsNeeded = 576 / encodingInWord; //_layer.length / encodingInWord;

    function encodeScene(uint8[] memory _scene) internal pure returns (bytes memory) {
        uint256[wordsNeeded] memory scene;
        for (uint16 i = 0; i < wordsNeeded; i++) {
            for (uint16 j = 0; j < encodingInWord; j++) {
                scene[i] += uint256(_scene[i * encodingInWord + j]) * unitSize**j; // Is this real actually. Only have 8 possibilities here
            }
        }
        return abi.encode(scene);
    }

    function decodeToWords(bytes memory _layer)
        internal
        pure
        returns (uint256[wordsNeeded] memory)
    {
        // For some reason I cannot use a constant but must manually write in `abi.decode`
        uint256[wordsNeeded] memory layer = abi.decode(_layer, (uint256[9]));
        return layer;
    }

    function decodeWord(uint256 _word) internal pure returns (uint8[encodingInWord] memory) {
        uint8[encodingInWord] memory wordVals;
        for (uint16 i = 0; i < encodingInWord; i++) {
            wordVals[i] = uint8((_word / unitSize**i) & (unitSize - 1));
        }
        return wordVals;
    }
}
