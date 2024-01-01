// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc1155/IArttacaERC1155Upgradeable.sol)

pragma solidity ^0.8.4;

import "./IERC1155Upgradeable.sol";
import "./LazyMint1155.sol";

/**
 * @title Arttaca ERC1155 interface, standard for Arttaca NFT collections.
 *
 * Contains the basic methods and functionalities that will be used for
 * Arttaca collections.
 */
interface IArttacaERC1155Upgradeable is IERC1155Upgradeable {

    struct TokenInformation {
        uint quantity;
        uint totalSupply;
        string uri;
        Ownership.Royalties royalties;
    }

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function factoryAddress() external view returns (address);

    function contractURI() external view returns (string memory);

    /**
     * @dev Allows Owner to mint new assets in the collection.
     *
     * Requirements:
     *
     * - The `msg.sender` is the owner.
     * - The value '_quantity' must be > than 0.
     * - The value '_to' must be different than a ZERO address.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function mintAndTransferByOwner(address _to, uint _tokenId, uint _quantity, string calldata _tokenURI, Ownership.Royalties memory _royalties) external;

    /**
     * @dev Allows anyone to mint assets if there's a valid owner signature.
     *
     * Requirements:
     *
     * - The value '_to' must be different than a ZERO address.
     * - The value '_quantity' must be > than 0.
     * - The value '_mintData' must contain valid signature for the values '_to' and '_tokenId'.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function mintAndTransfer(LazyMint1155.TokenData calldata _tokenData, address _to, uint256 _quantity) external;

    /**
     * @dev Get information about the token.
     *
     * Requirements:
     *
     * - The value '_tokenId' a valid & minted token id
     *
     * Returns a `TokenInformation` instance.
     */
    function getTokenInformation(uint _tokenId, address _holder) external view returns (TokenInformation memory tokenInformation);
}
