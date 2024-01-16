// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./AdminControlUpgradeable.sol";
import "./ERC721ProjectCoreUpgradeable.sol";
import "./ERC721AUpgradeable.sol";

/**
 * @dev ERC721Project implementation
 */
abstract contract ERC721AProjectUpgradeable is
    Initializable,
    AdminControlUpgradeable,
    ERC721AUpgradeable,
    ERC721ProjectCoreUpgradeable,
    UUPSUpgradeable
{
    function _initialize(string memory _name, string memory _symbol) internal initializer {
        __AdminControl_init();
        __ERC721A_init_unchained(_name, _symbol);
        __ERC721ProjectCore_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControlUpgradeable, ERC721AUpgradeable, ERC721ProjectCoreUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        _approveTransfer(from, to, tokenId);
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @dev See {IProjectCore-registerManager}.
     */
    function registerManager(
        address manager,
        string calldata baseURI,
        bool baseURIIdentical
    ) external override adminRequired nonBlacklistRequired(manager) {
        _registerManager(manager, baseURI, baseURIIdentical);
    }

    /**
     * @dev See {IProjectCore-unregisterManager}.
     */
    function unregisterManager(address manager) external override adminRequired {
        _unregisterManager(manager);
    }

    /**
     * @dev See {IProjectCore-blacklistManager}.
     */
    function blacklistManager(address manager) external override adminRequired {
        _blacklistManager(manager);
    }

    /**
     * @dev See {IProjectCore-managerSetBaseTokenURI}.
     */
    function managerSetBaseTokenURI(string calldata uri, bool identical) external override managerRequired {
        _managerSetBaseTokenURI(uri, identical);
    }

    /**
     * @dev See {IProjectCore-managerSetTokenURIPrefix}.
     */
    function managerSetTokenURIPrefix(string calldata prefix) external override managerRequired {
        _managerSetTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IProjectCore-managerSetTokenURI}.
     */
    function managerSetTokenURI(uint256 tokenId, string calldata uri) external override managerRequired {
        _managerSetTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IProjectCore-managerSetTokenURI}.
     */
    function managerSetTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external override managerRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _managerSetTokenURI(tokenIds[i], uris[i]);
        }
    }

    /**
     * @dev See {IProjectCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev See {IProjectCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IProjectCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IProjectCore-setTokenURI}.
     */
    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);
        }
    }

    /**
     * @dev See {IProjectCore-setMintPermissions}.
     */
    function setMintPermissions(address manager, address permissions) external override adminRequired {
        _setMintPermissions(manager, permissions);
    }

    /**
     * @dev See {IERC721ProjectCore-adminMint}.
     */
    function adminMint(address to, string calldata uri)
        external
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256)
    {
        return _adminOrManagerMint(to, uri, true);
    }

    /**
     * @dev See {IERC721ProjectCore-adminMintBatch}.
     */
    function adminMintBatch(address[] calldata recipients, string[] calldata uris)
        external
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256[] memory tokenIds)
    {
        require(recipients.length == uris.length, "Invalid input");
        tokenIds = new uint256[](recipients.length);
        for (uint16 i = 0; i < recipients.length; i++) {
            tokenIds[i] = _adminOrManagerMint(recipients[i], uris[i], true);
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721ProjectCore-adminMintBatch}.
     */
    function adminMintBatch(address to, string[] calldata uris)
        external
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = _adminOrManagerMintBatch(to, uris, true);

        return tokenIds;
    }

    /**
     * @dev Mint token
     */
    function _adminOrManagerMint(
        address to,
        string memory uri,
        bool isAdmin
    ) internal virtual returns (uint256 tokenId) {
        tokenId = _currentIndex;
        if (isAdmin) {
            // Track the manager that minted the token
            _tokensManager[tokenId] = address(this);
        } else {
            _checkMintPermissions(to, tokenId);
            // Track the manager that minted the token
            _tokensManager[tokenId] = msg.sender;
        }

        _safeMint(to, 1);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        // Call post mint
        _postMintBase(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Mint tokens > 1
     */
    function _adminOrManagerMintBatch(
        address to,
        string[] calldata uris,
        bool isAdmin
    ) internal virtual returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        uint256 tokenId = _currentIndex;

        _safeMint(to, uris.length);

        for (uint256 i = 0; i < uris.length; i++) {
            string memory uri = uris[i];
            if (isAdmin) {
                _tokensManager[tokenId] = address(this);
            } else {
                _checkMintPermissions(to, tokenId);
                _tokensManager[tokenId] = msg.sender;
            }

            if (bytes(uri).length > 0) {
                _tokenURIs[tokenId] = uri;
            }
            _postMintBase(to, tokenId);
            tokenIds[i] = tokenId++;
        }

        return tokenIds;
    }

    /**
     * @dev See {IERC721ProjectCore-managerMint}.
     */
    function managerMint(address to, string calldata uri)
        external
        virtual
        override
        nonReentrant
        managerRequired
        returns (uint256)
    {
        return _adminOrManagerMint(to, uri, false);
    }

    /**
     * @dev See {IERC721ProjectCore-managerMintBatch}.
     */
    function managerMintBatch(address[] calldata recipients, string[] calldata uris)
        external
        virtual
        override
        nonReentrant
        managerRequired
        returns (uint256[] memory tokenIds)
    {
        require(recipients.length == uris.length, "Invalid input");
        tokenIds = new uint256[](recipients.length);
        for (uint16 i = 0; i < recipients.length; i++) {
            tokenIds[i] = _adminOrManagerMint(recipients[i], uris[i], false);
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721ProjectCore-managerMintBatch}.
     */
    function managerMintBatch(address to, string[] calldata uris)
        external
        virtual
        override
        nonReentrant
        managerRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](uris.length);
        tokenIds = _adminOrManagerMintBatch(to, uris, false);

        return tokenIds;
    }

    /**
     * @dev See {IERC721ProjectCore-tokenManager}.
     */
    function tokenManager(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenManager(tokenId);
    }

    /**
     * @dev See {IERC721ProjectCore-burn}.
     */
    function burn(uint256 tokenId) public virtual override nonReentrant {
        address owner = ownerOf(tokenId);
        address approvedAddress = _tokenApprovals[tokenId];

        bool isApprovedOrOwner = (_msgSender() == owner ||
            isApprovedForAll(owner, _msgSender()) ||
            approvedAddress == _msgSender());
        require(isApprovedOrOwner, "Caller is not owner nor approved");
        _burn(tokenId);
        _postBurn(owner, tokenId);
    }

    /**
     * @dev See {IProjectCore-setDefaultRoyalties}.
     */
    function setDefaultRoyalty(address receiver, uint256 royaltyBPs) external override adminRequired {
        _setDefaultRoyalty(receiver, royaltyBPs);
    }

    /**
     * @dev See {IProjectCore-setTokenRoyalties}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 royaltyBPs
    ) external override adminRequired {
        _setTokenRoyalty(tokenId, receiver, royaltyBPs);
    }

    /**
     * @dev See {IProjectCore-setContractURI}
     */
    function setContractURI(string memory _uri) external override adminRequired {
        _setContractURI(_uri);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
