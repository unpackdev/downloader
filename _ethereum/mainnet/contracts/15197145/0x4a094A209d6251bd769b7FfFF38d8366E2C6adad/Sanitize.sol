// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Sanitize {
    /// @notice 34 for double quote, 39 for single quote
    function sanitizeForJSON(string memory s, uint8 quote)
        internal
        pure
        returns (string memory)
    {
        bytes memory b = bytes(s);
        uint8 ch;
        for (uint256 i = 0; i < b.length; i++) {
            ch = uint8(b[i]);
            if (
                ch < 32 || // "
                ch == quote
            ) {
                b[i] = " ";
            } else {
                b[i] = bytes1(ch);
            }
        }
        return string(b);
    }
}
