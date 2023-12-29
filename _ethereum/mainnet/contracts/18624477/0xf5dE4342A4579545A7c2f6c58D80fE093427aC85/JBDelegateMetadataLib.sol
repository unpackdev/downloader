// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./JBDelegateMetadataConstants.sol";

/**
 * @notice Library to parse and create delegate metadata
 *
 * @dev    Metadata are built as:
 *         - 32B of reserved space for the protocol
 *         - a lookup table `delegateId: offset`, defining the offset of the metadata for each delegate.
 *           The offset fits 1 bytes, the ID 4 bytes. This table is padded to 32B.
 *         - the metadata for each delegate, padded to 32B each
 *
 *            +-----------------------+ offset: 0
 *            | 32B reserved          |
 *            +-----------------------+ offset: 1 = end of first 32B
 *            | (delegate1 ID,offset1)|
 *            | (delegate2 ID,offset2)|
 *            | 0's padding           |
 *            +-----------------------+ offset: offset1 = 1 + number of words taken by the padded table
 *            | delegate 1 metadata1  |
 *            | 0's padding           |
 *            +-----------------------+ offset: offset2 = offset1 + number of words taken by the metadata1
 *            | delegate 2 metadata2  |
 *            | 0's padding           |
 *            +-----------------------+
 */
library JBDelegateMetadataLib {
    /**
     * @notice Parse the metadata to find the metadata for a specific delegate
     *
     * @dev    Returns false and an empty bytes if no metadata is found
     *
     * @param  _id             The delegate id to find
     * @param  _metadata       The metadata to parse
     *
     * @return _found          Whether the metadata was found
     * @return _targetMetadata The metadata for the delegate
     */
    function getMetadata(bytes4 _id, bytes calldata _metadata) internal pure returns (bool _found, bytes memory _targetMetadata) {
        // Either no metadata or empty one with only one selector (32+4+1)
        if (_metadata.length <= MIN_METADATA_LENGTH) return (false, "");

        // Get the first data offset - upcast to avoid overflow (same for other offset)
        uint256 _firstOffset = uint8(_metadata[RESERVED_SIZE + ID_SIZE]);

        // Parse the id's to find _id, stop when next offset == 0 or current = first offset
        for (uint256 _i = RESERVED_SIZE; _metadata[_i + ID_SIZE] != bytes1(0) && _i < _firstOffset * WORD_SIZE;) {
            uint256 _currentOffset = uint256(uint8(_metadata[_i + ID_SIZE]));

            // _id found?
            if (bytes4(_metadata[_i:_i + ID_SIZE]) == _id) {
                // Are we at the end of the lookup table (either at the start of data's or next offset is 0/in the padding)
                // If not, only return until from this offset to the begining of the next offset
                uint256 _end = (_i + NEXT_DELEGATE_OFFSET >= _firstOffset * WORD_SIZE || _metadata[_i + NEXT_DELEGATE_OFFSET] == 0)
                    ? _metadata.length
                    : uint256(uint8(_metadata[_i + NEXT_DELEGATE_OFFSET])) * WORD_SIZE;

                return (true, _metadata[_currentOffset * WORD_SIZE:_end]);
            }
            unchecked {
                _i += TOTAL_ID_SIZE;
            }
        }
    }

    /**
     * @notice Add a delegate to an existing metadata
     *
     * @param _idToAdd         The id of the delegate to add
     * @param _dataToAdd       The metadata of the delegate to add
     * @param _originalMetadata The original metadata
     *
     * @return _newMetadata    The new metadata with the delegate added
     */
    function addToMetadata(bytes4 _idToAdd, bytes calldata _dataToAdd, bytes calldata _originalMetadata) public pure returns (bytes memory _newMetadata) {
        // Get the first data offset - upcast to avoid overflow (same for other offset)...
        uint256 _firstOffset = uint8(_originalMetadata[RESERVED_SIZE + ID_SIZE]);

        // ...go back to the beginning of the previous word (ie the last word of the table, as it can be padded)
        uint256 _lastWordOfTable = _firstOffset - 1;

        // The last offset stored in the table and its index
        uint256 _lastOffset;

        uint256 _lastOffsetIndex;

        // The number of words taken by the last data stored
        uint256 _numberOfWordslastData;

        // Iterate to find the last entry of the table, _lastOffset - we start from the end as the first value encountered
        // will be the last offset
        for(uint256 _i = _firstOffset * WORD_SIZE - 1; _i > _lastWordOfTable * WORD_SIZE - 1;) {

            // If the byte is not 0, this is the last offset we're looking for
            if (_originalMetadata[_i] != 0) {
                _lastOffset = uint8(_originalMetadata[_i]);
                _lastOffsetIndex = _i;

                // No rounding as this should be padded to 32B
                _numberOfWordslastData = (_originalMetadata.length - _lastOffset * WORD_SIZE) / WORD_SIZE;

                // Copy the reserved word and the table and remove the previous padding
                _newMetadata = _originalMetadata[0 : _lastOffsetIndex + 1];

                // Check if the new entry is still fitting in this word
                if(_i + TOTAL_ID_SIZE >= _firstOffset * WORD_SIZE) {
                    // Increment every offset by 1 (as the table now takes one more word)
                    for (uint256 _j = RESERVED_SIZE + ID_SIZE; _j < _lastOffsetIndex + 1; _j += TOTAL_ID_SIZE) {
                        _newMetadata[_j] = bytes1(uint8(_originalMetadata[_j]) + 1);
                    }

                    // Increment the last offset so the new offset will be properly set too
                    _lastOffset++;
                }

                break;
            }

            unchecked {
                _i -= 1;
            }
        }

        // Add the new entry after the last entry of the table, the new offset is the last offset + the number of words taken by the last data
        _newMetadata = abi.encodePacked(_newMetadata, _idToAdd, bytes1(uint8(_lastOffset + _numberOfWordslastData)));

        // Pad as needed - inlined for gas saving
        uint256 _paddedLength =
            _newMetadata.length % WORD_SIZE == 0 ? _newMetadata.length : (_newMetadata.length / WORD_SIZE + 1) * WORD_SIZE;
        assembly {
            mstore(_newMetadata, _paddedLength)
        }

        // Add existing data at the end
        _newMetadata = abi.encodePacked(_newMetadata, _originalMetadata[_firstOffset * WORD_SIZE : _originalMetadata.length]);

        // Pad as needed
        _paddedLength =
            _newMetadata.length % WORD_SIZE == 0 ? _newMetadata.length : (_newMetadata.length / WORD_SIZE + 1) * WORD_SIZE;
        assembly {
            mstore(_newMetadata, _paddedLength)
        }

        // Append new data at the end
        _newMetadata = abi.encodePacked(_newMetadata, _dataToAdd);

        // Pad again again as needed
        _paddedLength =
            _newMetadata.length % WORD_SIZE == 0 ? _newMetadata.length : (_newMetadata.length / WORD_SIZE + 1) * WORD_SIZE;

        assembly {
            mstore(_newMetadata, _paddedLength)
        }
    }
}
