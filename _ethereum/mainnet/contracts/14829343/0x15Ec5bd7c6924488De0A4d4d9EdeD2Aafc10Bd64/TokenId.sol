// SPDX-License-Identifier: MIT
// Creator: JCBDEV
import "./console.sol";

pragma solidity ^0.8.4;

library TokenId {
    uint256 private constant _baseIdMask = ~uint256(type(uint128).max);

    function from(uint128 drop, uint128 mint)
        internal
        pure
        returns (uint256 tokenId)
    {
        tokenId |= uint256(drop) << 128;
        tokenId |= uint256(mint);

        return tokenId;
    }

    function firstTokenInDrop(uint256 tokenId) internal pure returns (uint256) {
        // console.log(_baseIdMask);
        // console.log(tokenId);
        // console.log(tokenId & _baseIdMask);

        return tokenId & _baseIdMask;
    }

    function dropId(uint256 tokenId) internal pure returns (uint128) {
        return uint128(tokenId >> 128);
    }

    function mintId(uint256 tokenId) internal pure returns (uint128) {
        return uint128(tokenId);
    }

    /// @notice extract the drop id and the sequence number from the token id
    /// @param tokenId The token id to extract the values from
    /// @return uint128 the drop id
    /// @return uint128 the sequence number
    function split(uint256 tokenId) internal pure returns (uint128, uint128) {
        return (uint128(tokenId >> 128), uint128(tokenId));
    }
}
