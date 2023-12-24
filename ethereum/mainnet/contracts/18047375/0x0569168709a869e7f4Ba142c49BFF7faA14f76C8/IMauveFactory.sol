// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Mauve Factory
/// @notice The Mauve Factory facilitates creation of Mauve pools and control over the protocol fees
interface IMauveFactory {
    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Emitted when a role address is changed via the factory
    /// @param oldRoleAddress The old address that was assigned to the roleChanged
    /// @param newRoleAddress The new address that is assigned to the roleChanged
    /// @param roleChanged The role key that was updated with a new address
    event RoleChanged(address indexed oldRoleAddress, address indexed newRoleAddress, bytes32 roleChanged);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Updates a role defined in the factory roled: [OWNER, POOLADMIN, POSITIONMANAGER, SWAPROUTER]
    /// @dev Must be called by the current owner
    /// @param _newRoleAddress The new address of the selected role on the factory
    /// @param roleKey The selected role to be changed on the factory
    function setRole(address _newRoleAddress, bytes32 roleKey) external;

    /// @notice Returns the current address registered as a role on the factory
    /// @dev Can be called by anyone
    /// @param roleKey The selected role to be retrieved from the factory
    /// @return The address of the respective roleKey
    function roles(bytes32 roleKey) external view returns (address);

    /// @notice Returns the currently approved VioletID tokens to interact with Mauve
    /// @dev This defines the set of VioletID tokens that are used by Mauve to authorize
    /// certain interactions. More specifically, an account must own at least one of these tokens to
    /// become the owner of a LP NFT via transfer or withdraw funds in case
    /// the emergency mode is activated.
    /// @return The list of VioletID tokens that are accepted
    function getMauveTokenIdsAllowedToInteract() external view returns (uint256[] memory);

    /// @notice Updates the current list of Token IDs allowed to interact
    /// @dev Must be called by the current owner
    /// @param tokenIds The VioletID tokenIDs that are accepted by Mauve
    function setMauveTokenIdsAllowedToInteract(uint256[] memory tokenIds) external;

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}
