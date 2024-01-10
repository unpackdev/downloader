//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INiftyForge721.sol";

/// @title IForgeMaster
/// @author Simon Fremaux (@dievardump)
/// @notice Interface to interact with the current ForgeMaster on a network
interface IForgeMaster {
    /// @notice Helper to know if the contract is locked
    /// @return if the contract is locked for new creations or not
    function isLocked() external view returns (bool);

    /// @notice Getter for the ERC721 Implementation
    function getERC721Implementation() external view returns (address);

    /// @notice Getter for the ERC1155 Implementation
    function getERC1155Implementation() external view returns (address);

    /// @notice Getter for the ERC721 OpenSea registry / proxy
    function getERC721ProxyRegistry() external view returns (address);

    /// @notice Getter for the ERC1155 OpenSea registry / proxy
    function getERC1155ProxyRegistry() external view returns (address);

    /// @notice allows to check if a slug can be used
    /// @param slug the slug to check
    /// @return if the slug is used
    function isSlugFree(string memory slug) external view returns (bool);

    /// @notice returns a registry address from a slug
    /// @param slug the slug to get the registry address
    /// @return the registry address
    function getRegistryBySlug(string memory slug)
        external
        view
        returns (address);

    /// @notice Helper to list all registries
    /// @param startAt the index to start at (will come in handy if one day we have too many contracts)
    /// @param limit the number of elements we request
    /// @return list of registries
    function listRegistries(uint256 startAt, uint256 limit)
        external
        view
        returns (address[] memory list);

    /// @notice Helper to list all modules
    /// @return list of modules
    function listModules() external view returns (address[] memory list);

    /// @notice helper to know if a token is flagged
    /// @param registry the registry
    /// @param tokenId the tokenId
    function isTokenFlagged(address registry, uint256 tokenId)
        external
        view
        returns (bool);

    /// @notice Creates a new NiftyForge721
    /// @dev the contract created is a minimal proxy to the _erc721Implementation
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ The contract base URI (where to find the NFTs) - can be empty ""
    /// @param owner_ Address to whom transfer ownership
    /// @param modulesInit array of ModuleInit
    /// @param contractRoyaltiesRecipient the recipient, if the contract has "contract wide royalties"
    /// @param contractRoyaltiesValue the value, modules to add / enable directly at creation
    /// @return newContract the address of the new contract
    function createERC721(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address owner_,
        INiftyForge721.ModuleInit[] memory modulesInit,
        address contractRoyaltiesRecipient,
        uint256 contractRoyaltiesValue,
        string memory slug,
        string memory context
    ) external returns (address newContract);

    /// @notice Creates a new NiftyForge721Slim
    /// @dev the contract created is a minimal proxy to the _erc721SlimImplementation
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ The contract base URI (where to find the NFTs) - can be empty ""
    /// @param owner_ Address to whom transfer ownership
    /// @param minter Address that  will be minting on the registry; Usually a module.
    /// @param contractRoyaltiesRecipient the recipient, if the contract has "contract wide royalties"
    /// @param contractRoyaltiesValue the value, modules to add / enable directly at creation
    /// @return newContract the address of the new contract
    function createERC721Slim(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address owner_,
        address minter,
        address contractRoyaltiesRecipient,
        uint256 contractRoyaltiesValue,
        string memory slug,
        string memory context
    ) external returns (address newContract);

    /// @notice Method allowing an editor to ask for reindexing on a regisytry
    ///         (for example if baseURI changes)
    ///         This will be listen to by the NiftyForgeMetadata graph, and launch;
    ///         - either a reindexation of alist of tokenIds (if tokenIds.length != 0)
    ///         - a full reindexation if tokenIds.length == 0
    ///         This can be very long and block the indexer
    ///         so calling this with a list of tokenIds > 10 or for a full reindexation is limited
    ///         Abuse on this function can also result in the Registry banned.
    ///         Only an Editor on the Registry can request a full reindexing
    /// @param registry the registry to reindex
    /// @param tokenIds the ids to reindex. If empty, will try to reindex all tokens for this registry
    function forceReindexing(address registry, uint256[] memory tokenIds)
        external;

    /// @notice Method allowing to flag a registry
    /// @param registry the registry to flag
    /// @param reason the reason to flag
    function flagRegistry(address registry, string memory reason) external;

    /// @notice Method allowing this owner, or an editor of the registry, to flag a token
    /// @param registry the registry to flag
    /// @param tokenId the tokenId
    /// @param reason the reason to flag
    function flagToken(
        address registry,
        uint256 tokenId,
        string memory reason
    ) external;

    /// @notice Setter for owner to stop the registries creation or not
    /// @param locked the new state
    function setLocked(bool locked) external;

    /// @notice Setter for the ERC721 Implementation
    /// @param implementation the address to proxy calls to
    function setERC721Implementation(address implementation) external;

    /// @notice Setter for the ERC1155 Implementation
    /// @param implementation the address to proxy calls to
    function setERC1155Implementation(address implementation) external;

    /// @notice Setter for the ERC721 OpenSea registry / proxy
    /// @param proxy the address of the proxy
    function setERC721ProxyRegistry(address proxy) external;

    /// @notice Setter for the ERC1155 OpenSea registry / proxy
    /// @param proxy the address of the proxy
    function setERC1155ProxyRegistry(address proxy) external;

    /// @notice Helper to add an official module to the list
    /// @param module address of the module to add to the list
    function addModule(address module) external;

    /// @notice Helper to remove an official module from the list
    /// @param module address of the module to remove from the list
    function removeModule(address module) external;

    /// @notice Allows to change the slug for a registry
    /// @dev only someone with Editor role on registry can call this
    /// @param slug the slug for the collection.
    ///        be aware that slugs will only work in the frontend if
    ///        they are composed of a-zA-Z0-9 and -
    ///        with no double dashed (--) allowed.
    ///        Any other character will render the slug invalid.
    /// @param registry the collection to link the slug with
    function setSlug(string memory slug, address registry) external;
}
