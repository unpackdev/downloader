// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./IL1ERC20Bridge.sol";

/// @title IL1SwapVault
/// @dev Interface for the L1 swap vault
interface IL1SwapVault {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding the data required to execute a swap
    struct ExecuteSwap {
        // The unique ID of the swap, used only for observability
        uint256 id;
        // The address of the L2 swap withdraw proxy, used only for observability
        address withdrawProxy;
        // The recipient of the L2 tokens
        address account;
        // The L1 collateral token being swapped out of
        address tokenIn;
        // The amount to swap
        uint256 amountIn;
        // The L1 token to swap to
        address tokenOut;
        // The L2 address of the token to swap to
        address l2TokenOut;
        // The minimum amount to receive in the swap
        uint256 amountOutMinimum;
        // The address of the target contract to call
        address target;
        // The data to call the target contract with
        bytes data;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a keeper is updated
    /// @param keeper The address of the keeper
    /// @param allowed True if the address is authorized, false otherwise
    event KeeperUpdated(address indexed keeper, bool indexed allowed);

    /// @notice Emitted when a whitelisted contract is updated
    /// @param target The address of the contract
    /// @param allowed True if the address is authorized, false otherwise
    event WhitelistUpdated(address indexed target, bool indexed allowed);

    /// @notice Emitted when a valid recipient is updated
    /// @param recipient The address of the recipient
    /// @param allowed True if the address is authorized, false otherwise
    event RecipientUpdated(address indexed recipient, bool indexed allowed);

    /// @notice Emitted when the dedication flag is updated
    /// @param dedicated True if the vault is dedicated, false otherwise
    event DedicationUpdated(bool indexed dedicated);

    /// @notice Emitted when a swap is executed
    /// @param id The unique ID of the swap, used only for observability
    /// @param withdrawProxy The address of the L2 swap withdraw proxy, used only for observability
    /// @param account The recipient of the L2 tokens
    /// @param tokenIn The L1 collateral token being swapped out of
    /// @param amountIn The amount to swap
    /// @param tokenOut The L1 token to swap to
    /// @param l2TokenOut The L2 address of the token to swap to
    /// @param amountOutMinimum The minimum amount to receive in the swap
    /// @param amountOut The amount received from the swap
    event Swapped(
        uint256 indexed id,
        address indexed withdrawProxy,
        address indexed account,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        address l2TokenOut,
        uint256 amountOutMinimum,
        uint256 amountOut
    );

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function updateKeeper(address keeper, bool allowed) external;

    function updateWhitelisted(address target, bool allowed) external;

    function updateRecipient(address recipient, bool allowed) external;
    function updateDedication(bool dedication) external;

    function withdrawReserves(address token, uint256 amount) external;

    function swap(ExecuteSwap calldata executeSwap) external returns (uint256 amountOut);

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);

    function l2Gas() external view returns (uint32);

    function l1Bridge() external view returns (IL1ERC20Bridge);

    function keepers(address) external view returns (bool);

    function whitelisted(address) external view returns (bool);
    function recipients(address) external view returns (bool);
    function dedicated() external view returns (bool);
}
