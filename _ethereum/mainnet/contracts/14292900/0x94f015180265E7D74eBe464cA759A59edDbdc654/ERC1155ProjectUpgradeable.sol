// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./AdminControlUpgradeable.sol";
import "./ERC1155ProjectCoreUpgradeable.sol";

/**
 * @dev ERC1155Project implementation
 */
abstract contract ERC1155ProjectUpgradeable is
    Initializable,
    AdminControlUpgradeable,
    ERC1155Upgradeable,
    ERC1155ProjectCoreUpgradeable,
    UUPSUpgradeable
{
    mapping(uint256 => uint256) private _totalSupply;

    function _initialize() internal initializer {
        __AdminControl_init();
        __ERC1155_init("");
        __ERC1155ProjectCore_init();

        __UUPSUpgradeable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControlUpgradeable, ERC1155Upgradeable, ERC1155ProjectCoreUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view returns (bool) {
        return totalSupply(id) > 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                _totalSupply[tokenIds[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                _totalSupply[tokenIds[i]] -= amounts[i];
            }
        }

        _approveTransfer(from, to, tokenIds, amounts);
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
    function managerSetBaseTokenURI(string calldata _uri, bool identical) external override managerRequired {
        _managerSetBaseTokenURI(_uri, identical);
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
    function managerSetTokenURI(uint256 tokenId, string calldata _uri) external override managerRequired {
        _managerSetTokenURI(tokenId, _uri);
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
    function setBaseTokenURI(string calldata _uri) external override adminRequired {
        _setBaseTokenURI(_uri);
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
    function setTokenURI(uint256 tokenId, string calldata _uri) external override adminRequired {
        _setTokenURI(tokenId, _uri);
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
        // removed mintPermissions to reduce size
        // _setMintPermissions(manager, permissions);
    }

    /**
     * @dev See {IERC1155ProjectCore-adminMintBatch}. batch mint tokenIds and amounts to each address in to
     */
    function adminMintBatch(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external virtual override nonReentrant adminRequired {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokensManager[tokenIds[i]] = address(this);
        }
        for (uint256 i = 0; i < to.length; i++) {
            _mintBatch(to[i], tokenIds, amounts, data);
        }
    }

    /**
     * @dev See {IERC1155ProjectCore-managerMintBatch}.
     */
    function managerMintBatch(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external virtual override nonReentrant managerRequired {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokensManager[tokenIds[i]] = _msgSender();
        }
        for (uint256 i = 0; i < to.length; i++) {
            _mintBatch(to[i], tokenIds, amounts, data);
        }
    }

    /**
     * @dev See {IERC1155ProjectCore-tokenManager}.
     */
    function tokenManager(uint256 tokenId) public view virtual override returns (address) {
        require(exists(tokenId), "Nonexistent token");
        return _tokenManager(tokenId);
    }

    /**
     * @dev See {IERC1155ProjectCore-burn}.
     */
    function burn(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes calldata data
    ) public virtual override nonReentrant {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(tokenIds.length == amounts.length, "Invalid input");
        if (tokenIds.length == 1) {
            _burn(account, tokenIds[0], amounts[0]);
        } else {
            _burnBatch(account, tokenIds, amounts);
        }
        _postBurn(account, tokenIds, amounts, data);
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
     * @dev See {IERC1155Metadata-tokenURI}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[49] private __gap;
}
