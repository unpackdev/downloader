// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow the bridge to mint and burn tokens
/// bridge must be able to mint and burn tokens on the multitoken contract
interface IERC1155Multinetwork {

    // transfer token to a different address
    function networkTransferFrom(
        address from,
        address to,
        uint256 network,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferNetworkERC1155(
        uint256 networkFrom,
        uint256 networkTo,
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

}
