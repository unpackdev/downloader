//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

/// @title The interface for Graviton lp-token lock-unlock
/// @notice Locks liquidity provision tokens
/// @author Artemij Artamonov - <array.clean@gmail.com>
/// @author Anton Davydov - <fetsorn@gmail.com>
interface ILockUnlockLP {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if locking is allowed
    function canLock() external view returns (bool);

    /// @notice Sets the permission to lock to `_canLock`
    function setCanLock(bool _canLock) external;

    /// @notice Look up if the locking of `token` is allowed
    function isAllowedToken(address token) external view returns (bool);

    /// @notice Look up if the locking of `token` is allowed
    function lockLimit(address token) external view returns (uint256);

    /// @notice Sets minimum lock amount limit for `token` to `_lockLimit`
    function setLockLimit(address token, uint256 _lockLimit) external;

    /// @notice The total amount of locked `token`
    function tokenSupply(address token) external view returns (uint256);

    /// @notice The total amount of all locked lp-tokens
    function totalSupply() external view returns (uint256);

    /// @notice Sets permission to lock `token` to `_isAllowedToken`
    function setIsAllowedToken(address token, bool _isAllowedToken) external;

    /// @notice The amount of `token` locked by `depositer`
    function balance(address token, address depositer)
        external
        view
        returns (uint256);

    /// @notice Transfers `amount` of `token` from the caller to LockUnlockLP
    function lock(address token, uint256 amount) external;

    /// @notice Transfers `amount` of `token` from LockUnlockLP to the caller
    function unlock(address token, uint256 amount) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `sender` locks `amount` of `token` lp-tokens
    /// @param token The address of the lp-token
    /// @param sender The account that locked lp-token
    /// @param receiver The account to whose lp-token balance the tokens are added
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of lp-tokens locked
    event Lock(
        address indexed token,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the `sender` unlocks `amount` of `token` lp-tokens
    /// @param token The address of the lp-token
    /// @param sender The account that locked lp-token
    /// @param receiver The account to whose lp-token balance the tokens are added
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of lp-tokens unlocked
    event Unlock(
        address indexed token,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the permission to lock token is updated via `#setIsAllowedToken`
    /// @param owner The owner account at the time of change
    /// @param token The lp-token whose permission was updated
    /// @param newBool Updated permission
    event SetIsAllowedToken(
        address indexed owner,
        address indexed token,
        bool indexed newBool
    );

    /// @notice Event emitted when the minimum lock amount limit updated via `#setLockLimit`
    /// @param owner The owner account at the time of change
    /// @param token The lp-token whose permission was updated
    /// @param _lockLimit New minimum lock amount limit
    event SetLockLimit(
        address indexed owner,
        address indexed token,
        uint256 indexed _lockLimit
    );

    /// @notice Event emitted when the permission to lock is updated via `#setCanLock`
    /// @param owner The owner account at the time of change
    /// @param newBool Updated permission
    event SetCanLock(address indexed owner, bool indexed newBool);
}
