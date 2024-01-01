// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.21;

/**
 * @dev Structure of a pool
 */
struct PoolState {
    uint112 totalCollected;
    uint112 poolSize;
    uint16 flags;
    uint16 depositors;
    uint32 endTime; // uint32 => year 2106
    address currency;
    address custodian;
    address signer;
}

/**
 * @dev Structure of parameters of a pool
 */
/**
 * @dev Structure of a pool
 */
struct PoolParameters {
    uint112 poolSize;
    uint32 endTime; // uint32 => year 2106
    uint16 flags;
    address currency;
    address custodian;
    address signer;
}

enum PoolParameter {
    POOL_SIZE,
    END_TIME, // UINT32 => YEAR 2106
    FLAGS,
    DEPOSITORS,
    CURRENCY,
    CUSTODIAN,
    SIGNER
}

enum PoolErrorReason {
    POOL_SIZE_TOO_SMALL,
    TRANSFER_FAILURE,
    ARITHMETIC_OUT_OF_BOUNDS,
    ALREADY_INVESTED_POOL,
    INVALID_POOL_TYPE
}

interface Poolable {
    error PoolClosed();
    error PoolOpen();
    error PoolError(PoolErrorReason reason);
    error IllegalPoolState(PoolParameter param);
    error IllegalPoolOperation(PoolErrorReason reason);
    error PoolInitialized();
    error PoolFull();
    error PoolNotFound();
    error PoolPaused();
    error Unauthorized();
    error PoolNotEmpty();

    event PoolCreation(string poolName);
    event PoolUpdate(string poolName);
    event Withdrawal(string poolName, uint256 indexed amount, address indexed to);

    function createPool(string calldata poolName, PoolParameters calldata params) external;

    function updatePool(string calldata poolName, PoolParameters calldata params) external;

    function poolExists(string calldata poolName) external view returns (bool);

    function poolState(string calldata poolName) external view returns (PoolState memory);
}
