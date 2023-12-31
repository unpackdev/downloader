// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./BytesLib.sol";
import "./BitMaps.sol";
import "./Errors.sol";
import "./CalldataBytesLib.sol";

library VerifierOptions {
    using BitMaps for BitMaps.BitMap256;
    using CalldataBytesLib for bytes;
    using BytesLib for bytes;

    uint8 internal constant WORKER_ID = 2;
    uint8 internal constant OPTION_TYPE_PRECRIME = 1;

    /// @dev group verifier options by its idx
    /// @param _options [verifier_id][verifier_option][verifier_id][verifier_option]...
    ///        verifier_option = [option_size][verifier_idx][option_type][option]
    ///        option_size = len(verifier_idx) + len(option_type) + len(option)
    ///        verifier_id: uint8, verifier_idx: uint8, option_size: uint16, option_type: uint8, option: bytes
    /// @return verifierOptions the grouped options, still share the same format of _options
    /// @return verifierIndices the verifier indices
    function groupVerifierOptionsByIdx(
        bytes memory _options
    ) internal pure returns (bytes[] memory verifierOptions, uint8[] memory verifierIndices) {
        if (_options.length == 0) return (verifierOptions, verifierIndices);

        uint8 numVerifiers = getNumVerifiers(_options);

        // if there is only 1 verifier, we can just return the whole options
        if (numVerifiers == 1) {
            verifierOptions = new bytes[](1);
            verifierOptions[0] = _options;

            verifierIndices = new uint8[](1);
            verifierIndices[0] = _options.toUint8(3); // verifier idx
            return (verifierOptions, verifierIndices);
        }

        // otherwise, we need to group the options by verifier_idx
        verifierIndices = new uint8[](numVerifiers);
        verifierOptions = new bytes[](numVerifiers);
        unchecked {
            uint cursor;
            uint start;
            uint8 lastVerifierIdx = 255; // 255 is an invalid verifier_idx

            while (cursor < _options.length) {
                ++cursor; // skip worker_id

                // optionLength asserted in getNumVerifiers (skip check)
                uint16 optionLength = _options.toUint16(cursor);
                cursor += 2;

                // verifierIdx asserted in getNumVerifiers (skip check)
                uint8 verifierIdx = _options.toUint8(cursor);

                // verifierIdx must equal to the lastVerifierIdx for the first option
                // so it is always skipped in the first option
                // this operation slices out options whenever the scan finds a different lastVerifierIdx
                if (lastVerifierIdx == 255) {
                    lastVerifierIdx = verifierIdx;
                } else if (verifierIdx != lastVerifierIdx) {
                    uint len = cursor - start - 3; // 3 is for worker_id and option_length
                    bytes memory opt = _options.slice(start, len);
                    _insertVerifierOptions(verifierOptions, verifierIndices, lastVerifierIdx, opt);

                    // reset the start and lastVerifierIdx
                    start += len;
                    lastVerifierIdx = verifierIdx;
                }

                cursor += optionLength;
            }

            // skip check the cursor here because the cursor is asserted in getNumVerifiers
            // if we have reached the end of the options, we need to process the last verifier
            uint size = cursor - start;
            bytes memory op = _options.slice(start, size);
            _insertVerifierOptions(verifierOptions, verifierIndices, lastVerifierIdx, op);

            // revert verifierIndices to start from 0
            for (uint8 i = 0; i < numVerifiers; ++i) {
                --verifierIndices[i];
            }
        }
    }

    function _insertVerifierOptions(
        bytes[] memory _verifierOptions,
        uint8[] memory _verifierIndices,
        uint8 _verifierIdx,
        bytes memory _newOptions
    ) internal pure {
        unchecked {
            // verifierIdx starts from 0 but default value of verifierIndices is 0,
            // so we tell if the slot is empty by adding 1 to verifierIdx
            require(_verifierIdx < 255, Errors.INVALID_VERIFIERS);
            uint8 verifierIdxAdj = _verifierIdx + 1;

            for (uint8 j = 0; j < _verifierIndices.length; ++j) {
                uint8 index = _verifierIndices[j];
                if (verifierIdxAdj == index) {
                    _verifierOptions[j] = abi.encodePacked(_verifierOptions[j], _newOptions);
                    break;
                } else if (index == 0) {
                    // empty slot, that means it is the first time we see this verifier
                    _verifierIndices[j] = verifierIdxAdj;
                    _verifierOptions[j] = _newOptions;
                    break;
                }
            }
        }
    }

    /// @dev get the number of unique verifiers
    /// @param _options the format is the same as groupVerifierOptionsByIdx
    function getNumVerifiers(bytes memory _options) internal pure returns (uint8 numVerifiers) {
        uint cursor;
        BitMaps.BitMap256 bitmap;

        // find number of unique verifier_idx
        unchecked {
            while (cursor < _options.length) {
                ++cursor; // skip worker_id

                uint16 optionLength = _options.toUint16(cursor);
                cursor += 2;
                require(optionLength >= 2, Errors.INVALID_VERIFIER_OPTION); // at least 1 byte for verifier_idx and 1 byte for option_type

                uint8 verifierIdx = _options.toUint8(cursor);

                // if verifierIdx is not set, increment numVerifiers
                // max num of verifiers is 255, 255 is an invalid verifier_idx
                require(verifierIdx < 255, Errors.INVALID_VERIFIERS);
                if (!bitmap.get(verifierIdx)) {
                    ++numVerifiers;
                    bitmap = bitmap.set(verifierIdx);
                }

                cursor += optionLength;
            }
        }
        require(cursor == _options.length, Errors.INVALID_VERIFIER_OPTION);
    }

    /// @dev decode the next verifier option from _options starting from the specified cursor
    /// @param _options the format is the same as groupVerifierOptionsByIdx
    /// @param _cursor the cursor to start decoding
    /// @return optionType the type of the option
    /// @return option the option
    /// @return cursor the cursor to start decoding the next option
    function nextVerifierOption(
        bytes calldata _options,
        uint _cursor
    ) internal pure returns (uint8 optionType, bytes calldata option, uint cursor) {
        unchecked {
            // skip worker id
            cursor = _cursor + 1;

            // read option size
            uint16 size = _options.toU16(cursor);
            cursor += 2;

            // read option type
            optionType = _options.toU8(cursor + 1); // skip verifier_idx

            // startCursor and endCursor are used to slice the option from _options
            uint startCursor = cursor + 2; // skip option type and verifier_idx
            uint endCursor = cursor + size;
            option = _options[startCursor:endCursor];
            cursor += size;
        }
    }
}
