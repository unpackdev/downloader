//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EnumerableSetUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IForgeMaster.sol";

import "./ForgeMasterStorage.sol";

import "./INiftyForge721.sol";
import "./INiftyForge721Slim.sol";

/// @title ForgeMaster
/// @author Simon Fremaux (@dievardump)
/// @notice This contract allows anyone to create ERC721 contract with role management
///         modules, Permits, on-chain Royalties, for pretty cheap.
///         Those contract & nfts are all referenced in the same Subgraph that can be used to create
///         a small, customizable, Storefront for anyone that wishes to.
contract ForgeMaster is IForgeMaster, OwnableUpgradeable, ForgeMasterStorage {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // emitted when a registry is created
    event RegistryCreated(address indexed registry, string context);

    // emitted when a slug is registered for a registry
    event RegistrySlug(address indexed registry, string slug);

    // emitted when a module is added to the list of official modules
    event ModuleAdded(address indexed module);

    // emitted when a module is removed from the list of official modules
    event ModuleRemoved(address indexed module);

    // Force reindexing for a registry
    // if tokenIds.length == 0 then a full reindexing will be performed
    // this will be done automatically in the "niftyforge metadata" graph
    // It might create a *very* long indexing process. Do not use for fun.
    // Abuse of reindexing might result in the registry being flagged
    // and banned from the public indexer
    event ForceIndexing(address registry, uint256[] tokenIds);

    // Flags a registry
    event FlagRegistry(address registry, address operator, string reason);

    // Flags a token
    event FlagToken(
        address registry,
        uint256 tokenId,
        address operator,
        string reason
    );

    function initialize(bool locked, address owner_) external initializer {
        __Ownable_init();

        _locked = locked;

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    /// @notice Helper to know if the contract is locked
    /// @return if the contract is locked for new creations or not
    function isLocked() external view returns (bool) {
        return _locked;
    }

    /// @notice Getter for the ERC721 Implementation
    function getERC721Implementation() public view returns (address) {
        return _erc721Implementation;
    }

    /// @notice Getter for the ERC1155 Implementation
    function getERC1155Implementation() public view returns (address) {
        return _erc1155Implementation;
    }

    /// @notice Getter for the ERC721 OpenSea registry / proxy
    function getERC721ProxyRegistry() public view returns (address) {
        return _openseaERC721ProxyRegistry;
    }

    /// @notice Getter for the ERC1155 OpenSea registry / proxy
    function getERC1155ProxyRegistry() public view returns (address) {
        return _openseaERC1155ProxyRegistry;
    }

    /// @notice allows to check if a slug can be used
    /// @param slug the slug to check
    /// @return if the slug is used
    function isSlugFree(string memory slug) external view returns (bool) {
        bytes32 bSlug = keccak256(bytes(slug));
        // verifies that the slug is not already in use
        return _slugsToRegistry[bSlug] != address(0);
    }

    /// @notice returns a registry address from a slug
    /// @param slug the slug to get the registry address
    /// @return the registry address
    function getRegistryBySlug(string memory slug)
        external
        view
        returns (address)
    {
        bytes32 bSlug = keccak256(bytes(slug));
        // verifies that the slug is not already in use
        require(_slugsToRegistry[bSlug] != address(0), '!UNKNOWN_SLUG!');
        return _slugsToRegistry[bSlug];
    }

    /// @notice Helper to list all registries
    /// @param startAt the index to start at (will come in handy if one day we have too many contracts)
    /// @param limit the number of elements we request
    /// @return list of registries
    function listRegistries(uint256 startAt, uint256 limit)
        external
        view
        returns (address[] memory list)
    {
        uint256 count = _registries.length();

        require(startAt < count, '!OVERFLOW!');

        if (startAt + limit > count) {
            limit = count - startAt;
        }

        list = new address[](limit);
        for (uint256 i; i < limit; i++) {
            list[i] = _registries.at(startAt + i);
        }
    }

    /// @notice Helper to list all modules
    /// @return list of modules
    function listModules() external view returns (address[] memory list) {
        uint256 count = _modules.length();
        list = new address[](count);
        for (uint256 i; i < count; i++) {
            list[i] = _modules.at(i);
        }
    }

    /// @notice helper to know if a token is flagged
    /// @param registry the registry
    /// @param tokenId the tokenId
    function isTokenFlagged(address registry, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _flaggedTokens[registry][tokenId];
    }

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
    ) external returns (address newContract) {
        require(_erc721Implementation != address(0), '!NO_721_IMPLEMENTATION!');

        // verify not locked or not owner
        require(_locked == false || msg.sender == owner(), '!LOCKED!');

        // create minimal proxy to _erc721Implementation
        newContract = ClonesUpgradeable.clone(_erc721Implementation);

        // initialize the non upgradeable proxy
        INiftyForge721(payable(newContract)).initialize(
            name_,
            symbol_,
            contractURI_,
            baseURI_,
            owner_ != address(0) ? owner_ : msg.sender,
            modulesInit,
            contractRoyaltiesRecipient,
            contractRoyaltiesValue
        );

        // add the new contract to the registry
        _addRegistry(newContract, context);

        if (bytes(slug).length > 0) {
            setSlug(slug, newContract);
        }
    }

    /// @notice Creates a new NiftyForge721Slim
    /// @dev the contract created is a minimal proxy to the _erc721SlimImplementation
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ The contract base URI (where to find the NFTs) - can be empty ""
    /// @param owner_ Address to whom transfer ownership
    /// @param minter The address that has the right to mint on the collection (see INiftyForge721Slim)
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
    ) external returns (address newContract) {
        require(
            _erc721SlimImplementation != address(0),
            '!NO_721SLIM_IMPLEMENTATION!'
        );

        // verify not locked or not owner
        require(_locked == false || msg.sender == owner(), '!LOCKED!');

        // create minimal proxy to _erc721SlimImplementation
        newContract = ClonesUpgradeable.clone(_erc721SlimImplementation);

        // initialize the non upgradeable proxy
        INiftyForge721Slim(newContract).initialize(
            name_,
            symbol_,
            contractURI_,
            baseURI_,
            owner_ != address(0) ? owner_ : msg.sender,
            minter,
            contractRoyaltiesRecipient,
            contractRoyaltiesValue
        );

        // add the new contract to the registry
        _addRegistry(newContract, context);

        if (bytes(slug).length > 0) {
            setSlug(slug, newContract);
        }
    }

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
        external
    {
        require(_registries.contains(registry), '!UNKNOWN_REGISTRY!');
        require(flaggedRegistries[registry] == false, '!FLAGGED_REGISTRY!');

        // only an editor can ask for a "big indexing"
        if (tokenIds.length == 0 || tokenIds.length > 10) {
            uint256 lastKnownIndexing = lastIndexing[registry];
            require(
                block.timestamp - lastKnownIndexing > 1 days,
                '!INDEXING_DELAY!'
            );

            require(
                INiftyForge721(payable(registry)).canEdit(msg.sender),
                '!NOT_EDITOR!'
            );
            lastIndexing[registry] = block.timestamp;
        }

        emit ForceIndexing(registry, tokenIds);
    }

    /// @notice Method allowing to flag a registry
    /// @param registry the registry to flag
    /// @param reason the reason to flag
    function flagRegistry(address registry, string memory reason)
        external
        onlyOwner
    {
        require(_registries.contains(registry), '!UNKNOWN_REGISTRY!');
        require(
            flaggedRegistries[registry] == false,
            '!REGISTRY_ALREADY_FLAGGED!'
        );

        flaggedRegistries[registry] = true;

        emit FlagRegistry(registry, msg.sender, reason);
    }

    /// @notice Method allowing this owner, or an editor of the registry, to flag a token
    /// @param registry the registry to flag
    /// @param tokenId the tokenId
    /// @param reason the reason to flag
    function flagToken(
        address registry,
        uint256 tokenId,
        string memory reason
    ) external {
        require(_registries.contains(registry), '!UNKNOWN_REGISTRY!');
        require(
            flaggedRegistries[registry] == false,
            '!REGISTRY_ALREADY_FLAGGED!'
        );
        require(
            _flaggedTokens[registry][tokenId] == false,
            '!TOKEN_ALREADY_FLAGGED!'
        );

        // only this contract owner, or an editor on the registry, can flag a token
        // tokens when they are flagged are not shown on the
        require(
            msg.sender == owner() ||
                INiftyForge721(payable(registry)).canEdit(msg.sender),
            '!NOT_EDITOR!'
        );

        _flaggedTokens[registry][tokenId] = true;

        emit FlagToken(registry, tokenId, msg.sender, reason);
    }

    /// @notice Setter for owner to stop the registries creation or not
    /// @param locked the new state
    function setLocked(bool locked) external onlyOwner {
        _locked = locked;
    }

    /// @notice Setter for the ERC721 Implementation
    /// @param implementation the address to proxy calls to
    function setERC721Implementation(address implementation) public onlyOwner {
        _setERC721Implementation(implementation);
    }

    /// @notice Setter for the ERC721Slim Implementation
    /// @param implementation the address to proxy calls to
    function setERC721SlimImplementation(address implementation)
        public
        onlyOwner
    {
        _setERC721SlimImplementation(implementation);
    }

    /// @notice Setter for the ERC1155 Implementation
    /// @param implementation the address to proxy calls to
    function setERC1155Implementation(address implementation) public onlyOwner {
        _setERC1155Implementation(implementation);
    }

    /// @notice Setter for the ERC721 OpenSea registry / proxy
    /// @param proxy the address of the proxy
    function setERC721ProxyRegistry(address proxy) public onlyOwner {
        _openseaERC721ProxyRegistry = proxy;
    }

    /// @notice Setter for the ERC1155 OpenSea registry / proxy
    /// @param proxy the address of the proxy
    function setERC1155ProxyRegistry(address proxy) public onlyOwner {
        _openseaERC1155ProxyRegistry = proxy;
    }

    /// @notice Helper to add an official module to the list
    /// @param module address of the module to add to the list
    function addModule(address module) external onlyOwner {
        if (_modules.add(module)) {
            emit ModuleAdded(module);
        }
    }

    /// @notice Helper to remove an official module from the list
    /// @param module address of the module to remove from the list
    function removeModule(address module) external onlyOwner {
        if (_modules.remove(module)) {
            emit ModuleRemoved(module);
        }
    }

    /// @notice Allows to change the slug for a registry
    /// @dev only someone with Editor role on registry can call this
    /// @param slug the slug for the collection.
    ///        be aware that slugs will only work in the frontend if
    ///        they are composed of a-zA-Z0-9 and -
    ///        with no double dashed (--) allowed.
    ///        Any other character will render the slug invalid.
    /// @param registry the collection to link the slug with
    function setSlug(string memory slug, address registry) public {
        bytes32 bSlug = keccak256(bytes(slug));

        // verifies that the slug is not already in use
        require(_slugsToRegistry[bSlug] == address(0), '!SLUG_IN_USE!');

        // verifies that the sender is a collection Editor or Owner
        require(
            INiftyForge721(payable(registry)).canEdit(msg.sender),
            '!NOT_EDITOR!'
        );

        // if the registry is already linked to a slug, free it
        bytes32 currentSlug = _registryToSlug[registry];
        if (currentSlug.length > 0) {
            delete _slugsToRegistry[currentSlug];
        }

        // if the new slug is not empty
        if (bytes(slug).length > 0) {
            _slugsToRegistry[bSlug] = registry;
            _registryToSlug[registry] = bSlug;
        } else {
            // remove registry to slug
            delete _registryToSlug[registry];
        }

        emit RegistrySlug(registry, slug);
    }

    /// @dev internal setter for the ERC721 Implementation
    /// @param implementation the address to proxy calls to
    function _setERC721Implementation(address implementation) internal {
        _erc721Implementation = implementation;
    }

    /// @dev internal setter for the ERC721Slim Implementation
    /// @param implementation the address to proxy calls to
    function _setERC721SlimImplementation(address implementation) internal {
        _erc721SlimImplementation = implementation;
    }

    /// @dev internal setter for the ERC1155 Implementation
    /// @param implementation the address to proxy calls to
    function _setERC1155Implementation(address implementation) internal {
        _erc1155Implementation = implementation;
    }

    /// @dev internal setter for new registries; emits an event RegistryCreated
    /// @param registry the new registry address
    function _addRegistry(address registry, string memory context) internal {
        _registries.add(registry);
        emit RegistryCreated(registry, context);
    }
}
