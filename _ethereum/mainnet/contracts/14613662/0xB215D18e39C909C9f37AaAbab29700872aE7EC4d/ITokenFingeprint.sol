// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC165.sol";


/**
 * @dev Interface for accessing sha256 fingerprint of the NFT data (not metadata).
 */
interface ITokenFingerprint is IERC165
{
    /**
     * @dev Returns sha256 fingerprint of the NFT data (not metadata),
     *      for example sha256 of NFT image file associated with token_id.
     */
    function fingerprintSha256(uint256 tokenId)
        external
        view
        returns (bytes32);
}
