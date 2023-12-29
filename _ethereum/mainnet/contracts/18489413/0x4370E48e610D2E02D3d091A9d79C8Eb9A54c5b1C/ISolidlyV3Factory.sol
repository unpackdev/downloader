// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Solidly V3 Factory
/// @notice The Solidly V3 Factory facilitates creation of Solidly V3 pools and control over the protocol fees
interface ISolidlyV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when the address authorized to collect pool fees is changed
    /// @param oldFeeCollector The fee collector before the change
    /// @param newFeeCollector The fee collector after the change
    event FeeCollectorChanged(address indexed oldFeeCollector, address indexed newFeeCollector);

    /// @notice Emitted when the fee setting auth status of an address is toggled
    /// @param addr The address whose fee setting auth status was toggled
    /// @param newStatus The new fee setting auth status of the address
    event FeeSetterStatusToggled(address indexed addr, uint256 indexed newStatus);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 fee,
        int24 indexed tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount (and associated tick spacing) is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the current fee collector of the factory
    /// @dev Can be changed by the current owner via setFeeCollector
    /// @return The address of the fee collector
    function feeCollector() external view returns (address);

    /// @notice Returns the fee setting auth status of an address
    /// @dev Can be changed by the current owner via toggleFeeSetterStatus
    /// @return Authorized status as uint (0: authorized to set fees, 1: not authorized to set fees)
    function isFeeSetter(address addr) external view returns (uint256);

    /// @notice Returns the set of addresses that are currently authorized to set pool fees
    /// @dev The underlying set that supports this view is updated every time the isFeeSetter mapping is updated
    /// It's maintained solely to provide an easy on-chain view of all currently authorized addresses
    /// @return Authorized status as uint (0: authorized to set fees, 1: not authorized to set fees)
    function getFeeSetters() external view returns (address[] memory);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a tick spacing value, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param tickSpacing The tick spacing value for the pool
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, int24 tickSpacing) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @dev The pool is uniquely identified by the two tokens and the tick spacing value. The fee is mutable post pool creation.
    /// @return pool The address of the newly created pool
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Updates the address that is authorized to collect pool fees
    /// @dev Must be called by the current owner
    /// @param _feeCollector The new fee collector
    function setFeeCollector(address _feeCollector) external;

    /// @notice Toggles the fee setting auth status of the address
    /// @dev Must be called by the current owner
    /// @param addr The address that will have its fee setting auth status toggled
    function toggleFeeSetterStatus(address addr) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}
