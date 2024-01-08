// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author jpegmint.xyz

import "./IERC721.sol";

/**
 * @dev NiftyBuilder interface stub for IPFS hash method.
 */
interface INiftyBuilder is IERC721 {
    /**
     * @dev Returns IPFS hash for the tokenId.
     */
    function tokenIPFSHash(uint256 tokenId) external view returns (string memory);
}
