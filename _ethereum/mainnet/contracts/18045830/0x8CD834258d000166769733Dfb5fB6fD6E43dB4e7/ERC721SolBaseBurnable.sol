// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// NFTC Open Source Contracts (https://github.com/NFTCulture/nftc-contracts/tree/main)
import "./ERC721SolBaseSupply.sol";

/**
 * @title ERC721SolBaseBurnable
 * @author @NiftyMike | @NFTCulture
 *
 * @dev ERC721 SolBase extension to enable tokens that can be irreversibly burned (destroyed).
 */
abstract contract ERC721SolBaseBurnable is ERC721SolBaseSupply {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId`.
     */
    function burn(uint256 tokenId) public virtual {
        address owner = _ownerOf[tokenId];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender] && msg.sender != getApproved[tokenId])
            revert Unauthorized();

        _burn(tokenId);
    }
}
