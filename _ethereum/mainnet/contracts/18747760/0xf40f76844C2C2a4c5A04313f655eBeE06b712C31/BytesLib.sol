// SPDX-License-Identifier: GPL-3.0-or-later

// A modified version of BytesLib
// Origin: https://github.com/1inch/universal-router/blob/b972662f8d3f0ba55ef99411720f613f77c3fab5/contracts/modules/uniswap/v3/BytesLib.sol
// Unused methods and constants were removed
pragma solidity 0.8.18;

library BytesLib {
    error ToAddressOverflow();
    error ToAddressOutOfBounds();

    /// @notice Returns the address starting at byte `_start`
    /// @dev _bytesLength must equal _bytes.length for this to function correctly
    /// @param _bytes The input bytes string to slice
    /// @param _start The starting index of the address
    /// @param _bytesLength The length of _bytes
    /// @return tempAddress The address starting at _start
    function toAddress(
        bytes memory _bytes,
        uint256 _start,
        uint256 _bytesLength
    ) internal pure returns (address tempAddress) {
        unchecked {
            if (_start + 20 < _start) revert ToAddressOverflow();
            if (_bytesLength < _start + 20) revert ToAddressOutOfBounds();
        }

        assembly {
            tempAddress := mload(add(add(_bytes, 0x14), _start))
        }
    }
}
