// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IProjectCoreUpgradeable.sol";

/**
 * @dev Core ERC1155 project interface
 */
interface IERC1155ProjectCoreUpgradeable is IProjectCoreUpgradeable {
    /**
     * @dev batch mint tokens with no manager. Can only be called by an admin. batch mint tokenIds and amounts to each address in to
     */
    function adminMintBatch(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @dev batch mint a token. Can only be called by a registered manager.
     * Returns tokenIds minted
     */
    function managerMintBatch(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @dev burn tokens. Can only be called by token owner or approved address.
     * On burn, calls back to the registered manager's onBurn method
     */
    function burn(
        address account,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
