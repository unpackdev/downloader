// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAccessControlUpgradeable.sol";
import "./IERC1155Upgradeable.sol";


interface IVault is IAccessControlUpgradeable, IERC1155Upgradeable {
    /// @notice Emitted when the base Uri of the vault changed
    /// @param oldBaseUri The Uri before the Uri was changed
    /// @param newBaseUri The Uri after the Uri was changed
    event BaseUriChanged(string indexed oldBaseUri, string indexed newBaseUri);

    /// @notice returns the base Uri of the Vault
    /// @return _baseUri Base Uri
    function getBaseUri() external view returns (string memory _baseUri);

    /// @notice Change the Base Uri to a new one in case of a metadata change - Admin only
    /// @param newUri The new Base Uri
    function setBaseUri(string memory newUri) external;

    /// @notice Return the URI for a given Token Id
    /// @param _id token id
    function uri(uint256 _id) external view returns (string memory);

    /**
     * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * @param to The address to mint tokens to
     * @param proof The 32 bytes hex value uniquely defining the asset
     * @param amount token amount to mint
     * @param data Additional data with no specified form
     *
     * Minter Only function
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        bytes32 proof,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {mint}.
     *
     * Requirements:
     *
     * - `proofs` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function mintBatch(
        address to,
        bytes32[] memory proofs,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /**
     * @notice Destroys `amount` tokens of token type `id` from its own wallet
     * @param proof The 32 bytes hex value uniquely defining the asset that should be burned
     * @param amount token amount to burn
     * @param signature signature needed to be allowed to burn
     *
     * Signature requirement  ensures the redemption process is initiated by Alt
     * Burning triggers physical redemption of the asset through Alt platform
     *
     * Burning without signature would mean being able to burn without triggering physical
     * redemption flow on Alt platform ie a pure value destruction deleterious to the user himself
     * We thus decided to prevent burning without signature.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        bytes32 proof,
        uint256 amount,
        bytes calldata signature
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `proofs` and `amounts` must have the same length.
     */
    function burnBatch(
        bytes32[] memory proofs,
        uint256[] memory amounts,
        bytes calldata signature
    ) external;

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external;
}
