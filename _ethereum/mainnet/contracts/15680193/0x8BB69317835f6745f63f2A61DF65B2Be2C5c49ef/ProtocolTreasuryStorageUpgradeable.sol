// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title ProtocolTreasuryStorageUpgradeable
 * @author NeatFi
 * @notice This contract holds the storage for NeatFi protocol
 *         treasury.
 */
contract ProtocolTreasuryStorageUpgradeable is Initializable {
    // Address of the Neat Token contract.
    address public neatTokenAddress;

    // Address of the NeatFi Vesting Escrow contract.
    address public vestingEscrowAddress;

    // Address of the NeatFi Protocol Settings contract.
    address public protocolSettingsAddress;

    // The pool of Ether to be distributed to Neat token locking addresses.
    uint256 public currentFeeDistributionPool;

    // The block timestamp of the last pool generation.
    uint256 public lastPoolGenerationTimestamp;

    // Shows the number of total locked Neat tokens by all holders.
    uint256 public totalLockedNeats;

    // Timestamp representation of a day.
    uint256 public constant DAY = 86400;

    enum LockerStatus {
        // 0: Locker is active and can yield protocol fees.
        ACTIVE,
        /* 
           1: Locker has locked tokens but is expired and 
           can not yield protocol fees.
         */
        EXPIRED,
        /*
           Locker was unlocked and has no locked tokens. Locker
           can not yield protocol fees.
         */
        UNLOCKED
    }

    /**
     * @dev The Locker struct that is created at the moment of locking
     *      Neat tokens.
     */
    struct Locker {
        // Address of the Neat tokens holder.
        address tokenHolder;
        // Amount of Neat tokens locked in this Locker.
        uint256 lockedTokenAmount;
        // Block timestamp of Locker creation.
        uint256 lockedAt;
        // Block timestamp when Locker can be unlocked.
        uint256 availableToUnlockAt;
        // Locker status.
        LockerStatus lockerStatus;
    }

    // Locker typehash.
    bytes32 constant LOCKER_TYPEHASH =
        keccak256(
            "Locker(address tokenHolder,uint256 lockedTokenAmount,uint256 lockedAt,uint256 availableToUnlockAt,bytes32 lockerHash,LockerStatus lockerStatus)"
        );

    /**
     * @dev Retrieves a locker by its hash.
     */
    mapping(bytes32 => Locker) public lockerInfo;

    /**
     * @dev Tracks the total number of Neat tokens locked by an
     *      address.
     */
    mapping(address => uint256) public lockedNeatsByAddress;

    /**
     * @dev Maps an address to its Lockers.
     */
    mapping(address => bytes32[]) public lockersByAddress;

    /**
     * @dev Maps an address to the timestamp of the last claim.
     */
    mapping(address => uint256) public lastClaimedTimestamp;

    /**
     * @dev Fired when a Locker struct is created.
     */
    event LockerCreated(Locker locker, bytes32 lockerHash);

    /**
     * @dev Fired when a Locker is unlocked.
     */
    event LockerUnlocked(Locker locker, bytes32 lockerHash);

    /**
     * @dev Fired when fee yield is claimed.
     */
    event YieldClaimed(address tokenHolder, uint256 yield);

    /**
     * @dev Fired when this contract receives Ether.
     */
    event EtherReceived(address sender, uint256 amount);

    /** Initializers */

    function __ProtocolTreasuryStorage_init() internal initializer {
        __ProtocolTreasuryStorage_init_unchained();
    }

    function __ProtocolTreasuryStorage_init_unchained() internal initializer {}
}
