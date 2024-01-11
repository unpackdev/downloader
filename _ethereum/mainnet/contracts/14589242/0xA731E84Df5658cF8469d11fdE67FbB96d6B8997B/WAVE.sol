//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Base64.sol";
import "./Strings.sol";
import "./ByteSwapping.sol";

library WAVE {
    bytes4 private constant _CHANK_ID = "RIFF";
    bytes4 private constant _FORMAT = "WAVE";
    bytes4 private constant _SUB_CHANK_1_ID = "fmt ";
    uint32 private constant _SUB_CHANK_1_SIZE = 16;
    uint16 private constant _AUDIO_FORMAT = 1;
    uint16 private constant _NUM_CHANNELS = 1;
    uint16 private constant _BITS_PER_SAMPLE = 16;
    bytes4 private constant _SUB_CHANK_2_SIZE = "data";

    int16 private constant _UPPER_AMPLITUDE = 16383;
    int16 private constant _LOWER_AMPLITUDE = -16383;

    uint256 private constant _MAX_SAMPLE_RATE = 8000;
    uint256 private constant _MIN_SAMPLE_RATE = 3000;

    uint256 private constant _MAX_HERTZ = 160;
    uint256 private constant _MIN_HERTZ = 10;
    uint256 private constant _HERTZ_BASE = 10;

    uint256 private constant _MAX_DUTY_CYCLE = 99;
    uint256 private constant _MIN_DUTY_CYCLE = 1;
    uint256 private constant _DUTY_CYCLE_BASE = 100;

    function calculateSampleRate(uint256 seed) internal pure returns (uint256) {
        return _ramdom(seed, _MAX_SAMPLE_RATE, _MIN_SAMPLE_RATE);
    }

    function calculateDutyCycle(uint256 seed) internal pure returns (uint256) {
        return _ramdom(seed, _MAX_DUTY_CYCLE, _MIN_DUTY_CYCLE);
    }

    function calculateHertz(uint256 seed) internal pure returns (uint256) {
        return _ramdom(seed, _MAX_HERTZ, _MIN_HERTZ);
    }

    function addDecimalPointToHertz(uint256 hertz)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                Strings.toString(hertz / _HERTZ_BASE),
                ".",
                Strings.toString(hertz % _HERTZ_BASE)
            );
    }

    function generate(
        uint256 sampleRate,
        uint256 hertz,
        uint256 dutyCycle
    ) internal pure returns (bytes memory) {
        bytes memory wave;

        uint256 waveWidth = (sampleRate / hertz) * _HERTZ_BASE;

        uint256 amplitudesLength = 1;
        while (waveWidth >= 2**amplitudesLength) {
            amplitudesLength++;
        }

        bytes[] memory upperAmplitudes = new bytes[](amplitudesLength);
        bytes[] memory lowerAmplitudes = new bytes[](amplitudesLength);
        upperAmplitudes[0] = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(_UPPER_AMPLITUDE))
        );
        lowerAmplitudes[0] = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(_LOWER_AMPLITUDE))
        );

        for (uint256 i = 1; i < amplitudesLength; i++) {
            uint256 lastIndex = i - 1;
            upperAmplitudes[i] = abi.encodePacked(
                upperAmplitudes[lastIndex],
                upperAmplitudes[lastIndex]
            );
            lowerAmplitudes[i] = abi.encodePacked(
                lowerAmplitudes[lastIndex],
                lowerAmplitudes[lastIndex]
            );
        }

        uint256 upperWaveWidth = (waveWidth * dutyCycle) / _DUTY_CYCLE_BASE;
        uint256 lowerWaveWidth = (waveWidth * (_DUTY_CYCLE_BASE - dutyCycle)) /
            _DUTY_CYCLE_BASE;
        uint256 adjustWaveWidth = sampleRate %
            (upperWaveWidth + lowerWaveWidth);

        bytes memory upperWave = _concatAmplitudes(
            upperAmplitudes,
            upperWaveWidth
        );
        bytes memory lowerWave = _concatAmplitudes(
            lowerAmplitudes,
            lowerWaveWidth
        );
        bytes memory adjustWave = _concatAmplitudes(
            upperAmplitudes,
            adjustWaveWidth
        );

        while (sampleRate * 2 >= wave.length + waveWidth * 2) {
            wave = abi.encodePacked(wave, upperWave, lowerWave);
        }
        wave = abi.encodePacked(wave, adjustWave);
        return _encode(uint32(sampleRate), wave);
    }

    function _ramdom(
        uint256 seed,
        uint256 max,
        uint256 min
    ) private pure returns (uint256) {
        return (seed % (max - min)) + min;
    }

    function _concatAmplitudes(bytes[] memory amplitudes, uint256 waveWidth)
        private
        pure
        returns (bytes memory)
    {
        bytes memory concated;
        uint256 lastAmplitudesIndex = amplitudes.length - 1;
        while (concated.length < waveWidth * 2) {
            uint256 gap = waveWidth * 2 - concated.length;
            for (uint256 i = lastAmplitudesIndex; i >= 0; i--) {
                if (gap >= amplitudes[i].length) {
                    concated = abi.encodePacked(concated, amplitudes[i]);
                    lastAmplitudesIndex = i;
                    break;
                }
            }
        }
        return concated;
    }

    function _encode(uint32 sampleRate, bytes memory data)
        private
        pure
        returns (bytes memory)
    {
        bytes memory raw = abi.encodePacked(
            _riffChunk(sampleRate),
            _fmtSubChunk(sampleRate),
            _dataSubChunk(sampleRate, data)
        );
        return abi.encodePacked("data:audio/wav;base64,", Base64.encode(raw));
    }

    function _riffChunk(uint32 sampleRate) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                _CHANK_ID,
                ByteSwapping.swapUint32(_chunkSize(sampleRate)),
                _FORMAT
            );
    }

    function _chunkSize(uint32 sampleRate) private pure returns (uint32) {
        return 4 + (8 + _SUB_CHANK_1_SIZE) + (8 + _subchunk2Size(sampleRate));
    }

    function _fmtSubChunk(uint32 sampleRate)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _SUB_CHANK_1_ID,
                ByteSwapping.swapUint32(_SUB_CHANK_1_SIZE),
                ByteSwapping.swapUint16(_AUDIO_FORMAT),
                ByteSwapping.swapUint16(_NUM_CHANNELS),
                ByteSwapping.swapUint32(sampleRate),
                ByteSwapping.swapUint32(_byteRate(sampleRate)),
                ByteSwapping.swapUint16(_blockAlign()),
                ByteSwapping.swapUint16(_BITS_PER_SAMPLE)
            );
    }

    function _byteRate(uint32 sampleRate) private pure returns (uint32) {
        return (sampleRate * _NUM_CHANNELS * _BITS_PER_SAMPLE) / 8;
    }

    function _blockAlign() private pure returns (uint16) {
        return (_NUM_CHANNELS * _BITS_PER_SAMPLE) / 8;
    }

    function _dataSubChunk(uint32 sampleRate, bytes memory data)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _SUB_CHANK_2_SIZE,
                ByteSwapping.swapUint32(_subchunk2Size(sampleRate)),
                data
            );
    }

    function _subchunk2Size(uint32 sampleRate) private pure returns (uint32) {
        return (sampleRate * _NUM_CHANNELS * _BITS_PER_SAMPLE) / 8;
    }
}
