// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";

import "./IERC1155ProjectApproveTransferManager.sol";
import "./IERC1155ProjectBurnableManager.sol";
import "./IERC1155ProjectCoreUpgradeable.sol";
import "./ProjectCoreUpgradeable.sol";

/**
 * @dev Core ERC1155 project implementation
 */
abstract contract ERC1155ProjectCoreUpgradeable is
    Initializable,
    ProjectCoreUpgradeable,
    IERC1155ProjectCoreUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev initializer
     */
    function __ERC1155ProjectCore_init() internal initializer {
        __ProjectCore_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC165_init_unchained();
        __ERC1155ProjectCore_init_unchained();
    }

    function __ERC1155ProjectCore_init_unchained() internal initializer {}

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
        return interfaceId == type(IERC1155ProjectCoreUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IProjectCore-managerSetApproveTransfer}.
     */
    function managerSetApproveTransfer(bool enabled) external override managerRequired {
        require(
            !enabled ||
                ERC165CheckerUpgradeable.supportsInterface(
                    msg.sender,
                    type(IERC1155ProjectApproveTransferManager).interfaceId
                ),
            "Manager must implement IERC1155ProjectApproveTransferManager"
        );
        if (_managerApproveTransfers[msg.sender] != enabled) {
            _managerApproveTransfers[msg.sender] = enabled;
            emit ManagerApproveTransferUpdated(msg.sender, enabled);
        }
    }

    /**
     * Post burn actions
     */
    function _postBurn(
        address owner,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(tokenIds.length > 0, "Invalid input");
        address manager = _tokensManager[tokenIds[0]];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokensManager[tokenIds[i]] == manager, "Mismatched token originators");
        }
        // Callback to originating extension if needed
        if (manager != address(this)) {
            if (ERC165CheckerUpgradeable.supportsInterface(manager, type(IERC1155ProjectBurnableManager).interfaceId)) {
                IERC1155ProjectBurnableManager(manager).onBurn(owner, tokenIds, amounts, data);
            }
        }
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        require(tokenIds.length > 0, "Invalid input");
        address manager = _tokensManager[tokenIds[0]];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokensManager[tokenIds[i]] == manager, "Mismatched token originators");
        }
        if (_managerApproveTransfers[manager]) {
            require(
                IERC1155ProjectApproveTransferManager(manager).approveTransfer(from, to, tokenIds, amounts),
                "Manager approval failure"
            );
        }
    }

    uint256[50] private __gap;
}
