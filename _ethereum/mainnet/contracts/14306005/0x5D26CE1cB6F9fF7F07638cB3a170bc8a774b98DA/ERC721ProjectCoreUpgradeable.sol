// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";

import "./IERC721ProjectApproveTransferManager.sol";
import "./IERC721ProjectBurnableManager.sol";
import "./IERC721ProjectMintPermissions.sol";
import "./IERC721ProjectCoreUpgradeable.sol";
import "./ProjectCoreUpgradeable.sol";

/**
 * @dev Core ERC721 project implementation
 */
abstract contract ERC721ProjectCoreUpgradeable is Initializable, ProjectCoreUpgradeable, IERC721ProjectCoreUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 _tokenCount;

    /**
     * @dev initializer
     */
    function __ERC721ProjectCore_init() internal initializer {
        __ProjectCore_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC165_init_unchained();
        __ERC721ProjectCore_init_unchained();
    }

    function __ERC721ProjectCore_init_unchained() internal initializer {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ProjectCoreUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC721ProjectCoreUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev totalSupply
     */
    function totalSupply() public view override returns (uint256) {
        return _tokenCount;
    }

    /**
     * @dev See {IProjectCore-managerSetApproveTransfer}.
     */
    function managerSetApproveTransfer(bool enabled) external override managerRequired {
        require(
            !enabled ||
                ERC165CheckerUpgradeable.supportsInterface(
                    msg.sender,
                    type(IERC721ProjectApproveTransferManager).interfaceId
                ),
            "Manager must implement IERC721ProjectApproveTransferManager"
        );
        if (_managerApproveTransfers[msg.sender] != enabled) {
            _managerApproveTransfers[msg.sender] = enabled;
            emit ManagerApproveTransferUpdated(msg.sender, enabled);
        }
    }

    /**
     * @dev Set mint permissions for an manager
     */
    function _setMintPermissions(address manager, address permissions) internal {
        require(_managers.contains(manager), "ProjectCore: Invalid manager");
        require(
            permissions == address(0x0) ||
                ERC165CheckerUpgradeable.supportsInterface(
                    permissions,
                    type(IERC721ProjectMintPermissions).interfaceId
                ),
            "Invalid address"
        );
        if (_managerPermissions[manager] != permissions) {
            _managerPermissions[manager] = permissions;
            emit MintPermissionsUpdated(manager, permissions, msg.sender);
        }
    }

    /**
     * Check if an manager can mint
     */
    function _checkMintPermissions(address to, uint256 tokenId) internal {
        if (_managerPermissions[msg.sender] != address(0x0)) {
            IERC721ProjectMintPermissions(_managerPermissions[msg.sender]).approveMint(msg.sender, to, tokenId);
        }
    }

    /**
     * Override for post mint actions
     */
    function _postMintBase(address, uint256) internal virtual {}

    /**
     * Override for post mint actions
     */
    function _postMintManager(address, uint256) internal virtual {}

    /**
     * Post-burning callback and metadata cleanup
     */
    function _postBurn(address owner, uint256 tokenId) internal virtual {
        // Callback to originating manager if needed
        if (_tokensManager[tokenId] != address(this)) {
            if (
                ERC165CheckerUpgradeable.supportsInterface(
                    _tokensManager[tokenId],
                    type(IERC721ProjectBurnableManager).interfaceId
                )
            ) {
                IERC721ProjectBurnableManager(_tokensManager[tokenId]).onBurn(owner, tokenId);
            }
        }
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        // Delete token origin manager tracking
        delete _tokensManager[tokenId];
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (_managerApproveTransfers[_tokensManager[tokenId]]) {
            require(
                IERC721ProjectApproveTransferManager(_tokensManager[tokenId]).approveTransfer(from, to, tokenId),
                "ERC721Project: Manager approval failure"
            );
        }
    }

    uint256[49] private __gap;
}
