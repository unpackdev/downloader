// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IERC1155Supply.sol";

/**
 * @title INToken
 *
 * @notice Defines the basic interface for an NToken.
 */
interface INToken is IERC1155Supply {
    /**
     * @dev Emitted when an yToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param params A set of encoded parameters for additional initialization
     */
    event Initialized(address indexed underlyingAsset, address indexed pool, address treasury, bytes params);

    /**
     * @notice Initializes the nToken
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this nToken (E.g. WETH for aWETH)
     * @param treasury The address of the treasury
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(address pool, address underlyingAsset, address treasury, bytes memory params) external;

    /**
     * @notice Mints `tokenId` nToken to `onBehalfOf`
     * @param onBehalfOf The address of the user that will receive the minted nToken
     * @param tokenId The tokenId getting minted
     * @param amount The amount getting minted
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address onBehalfOf, uint256 tokenId, uint256 amount) external returns (bool);

    /**
     * @notice Burns nToken from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param from The address from which the nToken will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param tokenId The tokenId being burned
     * @param amount The amount being burned
     */
    function burn(address from, address receiverOfUnderlying, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Returns the address of the underlying asset of this nToken
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the YLDR treasury, receiving the fees on this nToken.
     * @return Address of the YLDR treasury
     */
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Transfers nTokens in the event of a borrow being liquidated, in case the liquidators reclaims the nToken
     * @param from The address getting liquidated, current owner of the nTokens
     * @param to The recipient
     * @param tokenId The tokenId of tokens getting transferred
     * @param amount The amount of underlying tokens getting transferred
     * @param data Additional data with no specified format
     */
    function safeTransferFromOnLiquidation(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}
