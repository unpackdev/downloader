// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import "./IBaseURIConfigurable.sol";
import "./INonFungibleTokenQueryable.sol";

/**
 * @title INFTCAdvanceMint
 * @author @NFTCulture
 * @dev Interface to define standardized functionality that should be exposed
 * on NFTC Nifty contracts. This interface is tailored towards NFTs that are minted
 * in advance and then delivered to recipients via some to-be-determined mechanism.
 *
 * Supported Contract Specs:
 *  - ERC721SolBase
 *  - ERC721A Static
 *  - ERC721A Expandable
 *  - ERC1155
 */
interface INFTCAdvanceMint is IBaseURIConfigurable, INonFungibleTokenQueryable {
    // Tag Interface
}
