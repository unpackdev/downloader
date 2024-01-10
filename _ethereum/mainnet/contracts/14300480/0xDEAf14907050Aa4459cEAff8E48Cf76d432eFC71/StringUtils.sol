// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title String Utils
 *
 * Functions for converting numbers to strings and concatenating strings.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract StringUtils {

    /**
     * @notice Convert a `uint` value to a `string`
     * via OraclizeAPI - MIT licence
     * https://github.com/provable-things/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol#L896
     * @param _i the `uint` value to be converted
     * @return result the `string` representation of the given `uint` value
     */
    function uintToStr(uint _i)
    public pure
    returns (string memory result) {
        unchecked {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len - 1;
            while (_i != 0) {
                bstr[k--] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
            result = string(bstr);
        }
    }

    /**
     * @notice Concatenate two strings
     * @param _a the first string
     * @param _b the second string
     * @return result the concatenation of `_a` and `_b`
     */
    function strConcat(string memory _a, string memory _b)
    public pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

}