// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IRegistrationManager
 * @author pNetwork
 *
 * @notice
 */
interface IRegistrationManager {
    struct Registration {
        address owner;
        uint16 startEpoch;
        uint16 endEpoch;
        bytes1 kind;
    }

    /**
     * @dev Emitted when a borrowing sentinel is slashed.
     *
     * @param sentinel The sentinel
     */
    event BorrowingSentinelSlashed(address indexed sentinel);

    /**
     * @dev Emitted when a guardian is slashed.
     *
     * @param guardian The guardian
     */
    event GuardianSlashed(address indexed guardian);

    /**
     * @dev Emitted when a guardian is registered.
     *
     * @param owner The sentinel owner
     * @param startEpoch The epoch in which the registration starts
     * @param endEpoch The epoch at which the registration ends
     * @param guardian The sentinel address
     * @param kind The type of registration
     */
    event GuardianRegistrationUpdated(
        address indexed owner,
        uint16 indexed startEpoch,
        uint16 indexed endEpoch,
        address guardian,
        bytes1 kind
    );

    /**
     * @dev Emitted when a actor is light-resumed.
     *
     * @param actor The actor
     */
    event LightResumed(address indexed actor, bytes1 registrationKind);

    /**
     * @dev Emitted when a sentinel registration is completed.
     *
     * @param owner The sentinel owner
     * @param startEpoch The epoch in which the registration starts
     * @param endEpoch The epoch at which the registration ends
     * @param sentinel The sentinel address
     * @param kind The type of registration
     * @param amount The amount used to register a sentinel
     */
    event SentinelRegistrationUpdated(
        address indexed owner,
        uint16 indexed startEpoch,
        uint16 indexed endEpoch,
        address sentinel,
        bytes1 kind,
        uint256 amount
    );

    /**
     * @dev Emitted when a sentinel is hard-resumed.
     *
     * @param sentinel The sentinel
     */
    event SentinelHardResumed(address indexed sentinel);

    /**
     * @dev Emitted when a staking sentinel increased its amount at stake.
     *
     * @param sentinel The sentinel
     */
    event StakedAmountIncreased(address indexed sentinel, uint256 amount);

    /**
     * @dev Emitted when a staking sentinel is slashed.
     *
     * @param sentinel The sentinel
     * @param amount The amount
     */
    event StakingSentinelSlashed(address indexed sentinel, uint256 amount);

    /*
     * @notice Return the current signature nonce by the actor owner
     *
     * @param owner
     *
     */
    function getSignatureNonceByOwner(address owner) external view returns (uint256);

    /*
     * @notice Returns a guardian by its owner.
     *
     * @param owner
     *
     * @return the guardian.
     */
    function guardianOf(address owner) external view returns (address);

    /*
     * @notice Resume a sentinel that was hard-slashed that means that its amount went below 200k PNT
     *         and its address was removed from the merkle tree. In order to be able to hard-resume a
     *         sentinel, when the function is called, StakingManager.increaseAmount is also called in
     *         order to increase the amount at stake.
     *
     * @param amount
     * @param owner
     * @param signature
     * @param nonce
     *
     */
    function hardResume(uint256 amount, bytes calldata signature, uint256 nonce) external;

    /*
     * @notice Increase the duration of a staking sentinel registration.
     *
     * @param duration
     */
    function increaseSentinelRegistrationDuration(uint64 duration) external;

    /*
     * @notice Increase the duration  of a staking sentinel registration. This function is used togheter with
     *         onlyForwarder modifier in order to enable cross chain duration increasing
     *
     * @param owner
     * @param duration
     */
    function increaseSentinelRegistrationDuration(address owner, uint64 duration) external;

    /*
     * @notice Resume an actor that was light-slashed
     *
     * @param signature
     * @param nonce
     *
     */
    function lightResume(bytes calldata signature, uint256 nonce) external;

    /*
     * @notice Returns the sentinel of a given owner
     *
     * @param owner
     *
     * @return address representing the address of the sentinel.
     */
    function sentinelOf(address owner) external view returns (address);

    /*
     * @notice Returns the actor registration
     *
     * @param actor
     *
     * @return address representing the actor registration data.
     */
    function registrationOf(address actor) external view returns (Registration memory);

    /*
     * @notice Return the staked amount by a sentinel in a given epoch.
     *
     * @param epoch
     *
     * @return uint256 representing staked amount by a sentinel in a given epoch.
     */
    function sentinelStakedAmountByEpochOf(address sentinel, uint16 epoch) external view returns (uint256);

    /*
     * @notice Return the number of times an actor (sentinel or guardian) has been slashed in an epoch.
     *
     * @param epoch
     * @param actor
     *
     * @return uint16 representing the number of times an actor has been slashed in an epoch.
     */
    function slashesByEpochOf(uint16 epoch, address actor) external view returns (uint16);

    /*
     * @notice Set FeesManager
     *
     * @param feesManager
     *
     */
    function setFeesManager(address feesManager) external;

    /*
     * @notice Set GovernanceMessageEmitter
     *
     * @param feesManager
     *
     */
    function setGovernanceMessageEmitter(address governanceMessageEmitter) external;

    /*
     * @notice Slash a sentinel or a guardian. This function is callable only by the PNetworkHub
     *
     * @param actor
     * @param amount
     * @param challenger
     *
     */
    function slash(address actor, uint256 amount, address challenger, uint256 slashTimestamp) external;

    /*
     * @notice Return the total number of guardians in a specific epoch.
     *
     * @param epoch
     *
     * @return uint256 the total number of guardians in a specific epoch.
     */
    function totalNumberOfGuardiansByEpoch(uint16 epoch) external view returns (uint16);

    /*
     * @notice Return the total staked amount by the sentinels in a given epoch.
     *
     * @param epoch
     *
     * @return uint256 representing  total staked amount by the sentinels in a given epoch.
     */
    function totalSentinelStakedAmountByEpoch(uint16 epoch) external view returns (uint256);

    /*
     * @notice Return the total staked amount by the sentinels in a given epochs range.
     *
     * @param epoch
     *
     * @return uint256[] representing  total staked amount by the sentinels in a given epochs range.
     */
    function totalSentinelStakedAmountByEpochsRange(
        uint16 startEpoch,
        uint16 endEpoch
    ) external view returns (uint256[] memory);

    /*
     * @notice Update guardians registrations. UPDATE_GUARDIAN_REGISTRATION_ROLE is needed to call this function
     *
     * @param owners
     * @param numbersOfEpochs
     * @param guardians
     *
     */
    function updateGuardiansRegistrations(
        address[] calldata owners,
        uint16[] calldata numbersOfEpochs,
        address[] calldata guardians
    ) external;

    /*
     * @notice Update a guardian registration. UPDATE_GUARDIAN_REGISTRATION_ROLE is needed to call this function
     *
     * @param owners
     * @param numbersOfEpochs
     * @param guardians
     *
     */
    function updateGuardianRegistration(address owner, uint16 numberOfEpochs, address guardian) external;

    /*
     * @notice Registers/Renew a sentinel by borrowing the specified amount of tokens for a given number of epochs.
     *         This function is used togheter with onlyForwarder.
     *
     * @params owner
     * @param numberOfEpochs
     * @param signature
     * @param nonce
     *
     */
    function updateSentinelRegistrationByBorrowing(
        address owner,
        uint16 numberOfEpochs,
        bytes calldata signature,
        uint256 nonce
    ) external;

    /*
     * @notice Registers/Renew a sentinel by borrowing the specified amount of tokens for a given number of epochs.
     *
     * @param numberOfEpochs
     * @param signature
     * @param nonce
     *
     */
    function updateSentinelRegistrationByBorrowing(
        uint16 numberOfEpochs,
        bytes calldata signature,
        uint256 nonce
    ) external;

    /*
     * @notice Registers/Renew a sentinel for a given duration in behalf of owner
     *
     * @param amount
     * @param duration
     * @param signature
     * @param owner
     * @param nonce
     *
     */
    function updateSentinelRegistrationByStaking(
        address owner,
        uint256 amount,
        uint64 duration,
        bytes calldata signature,
        uint256 nonce
    ) external;
}
