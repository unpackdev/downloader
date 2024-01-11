//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./ERC1155.sol";
import "./AccessControl.sol";

/**
 * @title PermissionItems
 * @author Protofire
 * @dev Contract module which provides a permissioning mechanism through the asisgnation of ERC1155 tokens.
 * It inherits from standard ERC1155 and extends functionality for
 * role based access control and makes tokens non-transferable.
 */
contract PermissionItems is ERC1155, AccessControl {
    // Constants for roles assignments
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @dev Grants the contract deployer the default admin role.
     *
     */
    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Grants TRANSFER role to `account`.
     *
     * Grants MINTER role to `account`.
     * Grants BURNER role to `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setAdmin(address account) external {
        grantRole(MINTER_ROLE, account);
        grantRole(BURNER_ROLE, account);
    }

    /**
     * @dev Revokes TRANSFER role to `account`.
     *
     * Revokes MINTER role to `account`.
     * Revokes BURNER role to `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeAdmin(address account) external {
        revokeRole(MINTER_ROLE, account);
        revokeRole(BURNER_ROLE, account);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - the caller must have MINTER role.
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "PermissionItems: must have minter role to mint");

        super._mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "PermissionItems: must have minter role to mint");

        super._mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - the caller must have BURNER role.
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "PermissionItems: must have burner role to burn");
        super._burn(account, id, value);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "PermissionItems: must have burner role to burn");
        super._burnBatch(account, ids, values);
    }

    /**
     * @dev Disabled setApprovalForAll function.
     *
     */
    function setApprovalForAll(address, bool) public pure override {
        revert("disabled");
    }

    /**
     * @dev Disabled safeTransferFrom function.
     *
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert("disabled");
    }

    /**
     * @dev Disabled safeBatchTransferFrom function.
     *
     */
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert("disabled");
    }
}
