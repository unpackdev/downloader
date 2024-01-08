// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IProjectCoreUpgradeable.sol";

/**
 * @dev Core ERC721 project interface
 */
interface IERC721ProjectCoreUpgradeable is IProjectCoreUpgradeable {
    /**
     * @dev mint a token with no manager. Can only be called by an admin. set uri to empty string to use default uri.
     * Returns tokenId minted
     */
    function adminMint(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no manager. Can only be called by an admin.
     * Returns tokenId minted
     */
    function adminMintBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no manager. Can only be called by an admin.
     * Returns tokenId minted
     */
    function adminMintBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered manager. set uri to "" to use default uri
     * Returns tokenId minted
     */
    function managerMint(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered manager.
     * Returns tokenIds minted
     */
    function managerMintBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered manager.
     * Returns tokenId minted
     */
    function managerMintBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered manager's onBurn method
     */
    function burn(uint256 tokenId) external;
}
