// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ITokenFingeprint.sol";


contract TokenFingerprint is ITokenFingerprint
{
    mapping(uint256 => bytes32) private _tokenDataFingerprintSha256;

    function fingerprintSha256(uint256 tokenId)
        external
        view
        override
        returns (bytes32)
    {
        return _tokenDataFingerprintSha256[tokenId];
    }

    function _setFingerprint(uint256 tokenId, bytes32 tokenDataFingerprintSha256)
        internal
        virtual
    {
        _tokenDataFingerprintSha256[tokenId] = tokenDataFingerprintSha256;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == type(ITokenFingerprint).interfaceId;
    }
}
