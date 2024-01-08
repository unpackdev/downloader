// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC165Upgradeable.sol";

/**
 * @dev Core project interface
 */
interface IProjectCoreUpgradeable is IERC165Upgradeable {
    event ManagerRegistered(address indexed manager, address indexed sender);
    event ManagerUnregistered(address indexed manager, address indexed sender);
    event ManagerBlacklisted(address indexed manager, address indexed sender);
    event MintPermissionsUpdated(address indexed manager, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ManagerRoyaltiesUpdated(address indexed manager, address payable[] receivers, uint256[] basisPoints);
    event ManagerApproveTransferUpdated(address indexed manager, bool enabled);

    /**
     * @dev totalSupply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev gets address of all managers
     */
    function getManagers() external view returns (address[] memory);

    /**
     * @dev add an manager.  Can only be called by contract owner or admin.
     * manager address must point to a contract implementing IProjectManager.
     * Returns True if newly added, False if already added.
     */
    function registerManager(address manager, string calldata baseURI) external;

    /**
     * @dev add an manager.  Can only be called by contract owner or admin.
     * manager address must point to a contract implementing IProjectManager.
     * Returns True if newly added, False if already added.
     */
    function registerManager(
        address manager,
        string calldata baseURI,
        bool baseURIIdentical
    ) external;

    /**
     * @dev add an manager.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterManager(address manager) external;

    /**
     * @dev blacklist an manager.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified manager. It will also unregister the manager if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistManager(address manager) external;

    /**
     * @dev set the baseTokenURI of an manager.  Can only be called by manager.
     */
    function managerSetBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an manager.  Can only be called by manager.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function managerSetBaseTokenURI(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an manager.  Can only be called by manager.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function managerSetTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token manager.  Can only be called by manager that minted token.
     */
    function managerSetTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token manager for multiple tokens.  Can only be called by manager that minted token.
     */
    function managerSetTokenURI(uint256[] calldata tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no manager.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no manager.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no manager.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no manager.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an manager.  Used to control minting.
     */
    function setMintPermissions(address manager, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be manager) gets approval
     * from the manager before transferring
     */
    function managerSetApproveTransfer(bool enabled) external;

    /**
     * @dev get the manager of a given token
     */
    function tokenManager(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Set royalties of an manager
     */
    function setRoyaltiesManager(
        address manager,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);

    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);

    function getFeeBps(uint256 tokenId) external view returns (uint256[] memory);

    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);

    function royaltyInfo(
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    )
        external
        view
        returns (
            address,
            uint256,
            bytes memory
        );
}
