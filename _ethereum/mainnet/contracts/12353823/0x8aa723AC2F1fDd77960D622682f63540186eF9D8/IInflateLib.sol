// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IInflateLib {

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    /*
     * @dev Deflate algorithm
     *
     * Start deflating from `offset` bytes into `source`
     */
    function puffFromOffset(bytes calldata source, uint256 destlen, uint256 offset)
        external
        pure
        returns (ErrorCode, bytes memory);

    /*
     * @dev Deflate algorithm
     */
    function puff(bytes calldata source, uint256 destlen)
        external
        pure
        returns (ErrorCode, bytes memory);

    /*
     * @dev Smart decode routine expects either of this as input:
     * - Option 1: Uncompressed UTF-8 text (or actually any raw binary data that does not satisfy the magic header of option 2)
     * - Option 2: Deflated data structured as follows:
     *               Byte 0 = 0x1f
     *               Byte 1 = 0x8b
     *               Bytes 2-4 = size in bytes of uncompressed data
     *               Bytes 5-... = raw deflated data
     */
    function smartDecode(bytes calldata source)
        external 
        pure
        returns (ErrorCode, bytes memory);

}