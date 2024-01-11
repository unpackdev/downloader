/**
 * @title ISSR
 * @notice Has all the external functions, structs, events and errors for SSR.sol.
 */
interface ISSR {
    ///@dev Determines who has access to call a specific function.
    enum Access {
        Owner,
        Guardian,
        OwnerAndGuardian,
        RecoveryOwnerAndGuardian,
        OwnerAndRecoveryOwner
    }

    event WalletLocked();
    event WalletUnlocked();
    event RecoveryUnlocked();
    event NewGuardian(address newGuardian);
    event GuardianRemoved(address removedGuardian);
    event WalletRecovered(address newOwner, address newRecoveryOwner);

    ///@dev addGuardian() custom errors.
    error SSR__addGuardian__invalidAddress();

    ///@dev removeGuardian() custom errors.
    error SSR__removeGuardian__invalidAddress();
    error SSR__removeGuardian__incorrectPreviousGuardian();
    error SSR__removeGuardian__underflow();

    ///@dev initGuardians() custom errors.
    error SSR__initGuardians__zeroGuardians();
    error SSR__initGuardians__invalidAddress();

    ///@dev access() custom errors.
    error SSR__access__guardiansBlocked();
    error SSR__access__walletLocked();

    ///@dev verifyOwner() custom errors.
    error SSR__verifyOwner__invalidSignature();
    error SSR__verifyOwner__notOwner();

    ///@dev verifyGuardian() custom errors.
    error SSR__verifyGuardian__invalidSignature();
    error SSR__verifyGurdian__notGuardian();

    ///@dev verifyOwnerAndGuardian() custom errors.
    error SSR__verifyOwnerAndGuardian__invalidSignature();
    error SSR__verifyOwnerAndGuardian__notOwner();
    error SSR__verifyOwnerAndGuardian__notGuardian();

    ///@dev verifyRecoveryOwnerAndGurdian() custom errors.
    error SSR__verifyRecoveryOwnerAndGurdian__invalidSignature();
    error SSR__verifyRecoveryOwnerAndGurdian__notRecoveryOwner();
    error SSR__verifyRecoveryOwnerAndGurdian__notGuardian();

    ///@dev verifyOwnerAndRecoveryOwner() custom errors.
    error SSR__verifyOwnerAndRecoveryOwner__invalidSignature();
    error SSR__verifyOwnerAndRecoveryOwner__notOwner();
    error SSR__verifyOwnerAndRecoveryOwner__notRecoveryOwner();

    /**
     * @dev Locks the wallet. Can only be called by a guardian.
     */
    function lock() external;

    /**
     * @dev Unlocks the wallet. Can only be called by a guardian + the owner.
     */
    function unlock() external;

    /**
     * @dev Unlocks the wallet. Can only be called by the recovery owner + the owner.
     * This is to avoid the wallet being locked forever if a guardian misbehaves.
     * The guardians will be locked until the owner decides otherwise.
     */
    function recoveryUnlock() external;

    /**
     * @dev Unlocks the guardians. This can only be called by the owner.
     */
    function unlockGuardians() external;

    /**
     * @dev Can only recover with the signature of the recovery owner and guardian.
     * @param newOwner The new owner address. This is generated instantaneously.
     * @param newRecoveryOwner The new recovery owner address. This is generated instantaneously.
     * @notice The newOwner and newRecoveryOwner key pair should be generated from the mobile device.
     * The main reason of this is to restart the generation process in case an attacker has the current recoveryOwner.
     */
    function recover(address newOwner, address newRecoveryOwner) external;

    /**
     * @dev Adds a guardian to the wallet.
     * @param newGuardian Address of the new guardian.
     * @notice Can only be called by the owner.
     */
    function addGuardian(address newGuardian) external;

    /**
     * @dev Removes a guardian to the wallet.
     * @param prevGuardian Address of the previous guardian in the linked list.
     * @param guardianToRemove Address of the guardian to be removed.
     * @notice Can only be called by the owner.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove)
        external;

    /**
     * @param guardian Requested address.
     * @return Boolean if the address is a guardian of the current wallet.
     */
    function isGuardian(address guardian) external view returns (bool);

    /**
     * @return Array of guardians of this.
     */
    function getGuardians() external view returns (address[] memory);
}
