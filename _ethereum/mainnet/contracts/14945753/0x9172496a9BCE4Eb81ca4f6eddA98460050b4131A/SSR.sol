// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import "./SelfAuthorized.sol";
import "./Owner.sol";
import "./IEIP1271.sol";
import "./IERC165.sol";
import "./ISSR.sol";
import "./Utils.sol";

/**
 * @title SSR - Sovereign Social Recovery
 * @notice New wallet recovery mechanism.
 * @author Rodrigo Herrera I.
 */
contract SSR is ISSR, SelfAuthorized, Owner, Utils {
    ///@dev pointer address for the nested mapping.
    address internal constant pointer = address(0x1);

    uint256 internal guardianCount;

    bool public isLocked;

    ///@dev If guardians are blocked, they cannot do any transaction.
    ///This is to completely prevent from guardians misbehaving.
    bool public guardiansBlocked;

    mapping(address => address) internal guardians;

    /**
     * @dev Locks the wallet. Can only be called by a guardian.
     */
    function lock() external authorized {
        isLocked = true;
        emit WalletLocked();
    }

    /**
     * @dev Unlocks the wallet. Can only be called by a guardian + the owner.
     */
    function unlock() external authorized {
        isLocked = false;
        emit WalletUnlocked();
    }

    /**
     * @dev Unlocks the wallet. Can only be called by the recovery owner + the owner.
     * This is to avoid the wallet being locked forever if a guardian misbehaves.
     * The guardians will be locked until the owner decides otherwise.
     */
    function recoveryUnlock() external authorized {
        isLocked = false;
        guardiansBlocked = true;
        emit RecoveryUnlocked();
    }

    /**
     * @dev Unlocks the guardians. This can only be called by the owner.
     */
    function unlockGuardians() external authorized {
        guardiansBlocked = false;
    }

    /**
     * @dev Can only recover with the signature of 1 guardian and the recovery owner.
     * @param newOwner The new owner address. This is generated instantaneously.
     * @param newRecoveryOwner The new recovery owner address. This is generated instantaneously.
     * @notice The newOwner and newRecoveryOwner key pair should be generated from the mobile device.
     * The main reason of this is to restart the generation process in case an attacker has the current recoveryOwner.
     */
    function recover(address newOwner, address newRecoveryOwner)
        external
        authorized
    {
        checkParams(newOwner, newRecoveryOwner);
        owner = newOwner;
        recoveryOwner = newRecoveryOwner;
        emit WalletRecovered(newOwner, newRecoveryOwner);
    }

    /**
     * @dev Adds a guardian to the wallet.
     * @param newGuardian Address of the new guardian.
     * @notice Can only be called by the owner.
     */
    function addGuardian(address newGuardian) external authorized {
        if (
            newGuardian == address(0) ||
            newGuardian == owner ||
            guardians[newGuardian] != address(0)
        ) revert SSR__addGuardian__invalidAddress();
        if (!IERC165(newGuardian).supportsInterface(0x1626ba7e))
            revert SSR__addGuardian__invalidAddress();

        guardians[newGuardian] = guardians[pointer];
        guardians[pointer] = newGuardian;

        unchecked {
            // Won't overflow...
            ++guardianCount;
        }
        emit NewGuardian(newGuardian);
    }

    /**
     * @dev Removes a guardian to the wallet.
     * @param prevGuardian Address of the previous guardian in the linked list.
     * @param guardianToRemove Address of the guardian to be removed.
     * @notice Can only be called by the owner.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove)
        external
        authorized
    {
        if (guardianToRemove == pointer) {
            revert SSR__removeGuardian__invalidAddress();
        }

        if (guardians[prevGuardian] != guardianToRemove) {
            revert SSR__removeGuardian__incorrectPreviousGuardian();
        }

        // There needs to be at least 1 guardian ..
        if (guardianCount - 1 < 1) revert SSR__removeGuardian__underflow();

        guardians[prevGuardian] = guardians[guardianToRemove];
        guardians[guardianToRemove] = address(0);
        unchecked {
            //Won't underflow...
            --guardianCount;
        }
        emit GuardianRemoved(guardianToRemove);
    }

    /**
     * @param guardian Requested address.
     * @return Boolean if the address is a guardian of the current wallet.
     */
    function isGuardian(address guardian) external view returns (bool) {
        return guardian != pointer && guardians[guardian] != address(0);
    }

    /**
     * @return Array of guardians of this.
     */
    function getGuardians() public view returns (address[] memory) {
        address[] memory guardiansArray = new address[](guardianCount);
        address currentGuardian = guardians[pointer];

        uint256 index = 0;
        while (currentGuardian != pointer) {
            guardiansArray[index] = currentGuardian;
            currentGuardian = guardians[currentGuardian];
            index++;
        }
        return guardiansArray;
    }

    /**
     * @dev Sets up the initial guardian configuration. Can only be called from the init function.
     * @param _guardians Array of guardians.
     */
    function initGuardians(address[] calldata _guardians) internal {
        uint256 guardiansLength = _guardians.length;
        if (guardiansLength < 1) revert SSR__initGuardians__zeroGuardians();

        address currentGuardian = pointer;

        for (uint256 i = 0; i < guardiansLength; ) {
            address guardian = _guardians[i];
            if (
                guardian == owner ||
                guardian == address(0) ||
                guardian == pointer ||
                guardian == currentGuardian ||
                guardians[guardian] != address(0)
            ) revert SSR__initGuardians__invalidAddress();

            if (guardian.code.length > 0) {
                // If the guardian is a smart contract wallet, it needs to support EIP1271.
                if (!IERC165(guardian).supportsInterface(0x1626ba7e))
                    revert SSR__initGuardians__invalidAddress();
            }

            unchecked {
                // Won't overflow...
                ++i;
            }
            guardians[currentGuardian] = guardian;
            currentGuardian = guardian;
        }

        guardians[currentGuardian] = pointer;
        guardianCount = guardiansLength;
    }

    /**
     * @dev Returns who has access to call a specific function.
     * @param funcSelector The function selector: bytes4(keccak256(...)).
     */
    function access(bytes4 funcSelector) internal view returns (Access) {
        if (funcSelector == this.lock.selector) {
            // Only a guardian can lock the wallet ...
            // If  guardians are locked, we revert ...
            if (guardiansBlocked) revert SSR__access__guardiansBlocked();
            else return Access.Guardian;
        } else if (funcSelector == this.unlock.selector) {
            // Only a guardian + the owner can unlock the wallet ...
            return Access.OwnerAndGuardian;
        } else if (funcSelector == this.recoveryUnlock.selector) {
            // This is in case a guardian is misbehaving ...
            return Access.OwnerAndRecoveryOwner;
        } else if (funcSelector == this.recover.selector) {
            // Only the recovery owner + the guardian can recover the wallet (change the owner keys) ...
            return Access.RecoveryOwnerAndGuardian;
        } else {
            // Else is the owner ... If the the wallet is locked, we revert ...
            if (isLocked) revert SSR__access__walletLocked();
            else return Access.Owner;
        }
    }

    /**
     * @dev Verifies that the signature matches the owner.
     */
    function verifyOwner(bytes32 dataHash, bytes memory signature)
        internal
        view
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length < 65)
            revert SSR__verifyGuardian__invalidSignature();

        (r, s, v) = splitSigs(signature, 0);
        address recovered = returnSigner(dataHash, r, s, v);
        if (recovered != owner) revert SSR__verifyOwner__notOwner();
    }

    /**
     * @dev Verifies that the signature matches a guardian.
     */
    function verifyGuardian(bytes32 dataHash, bytes memory signature)
        internal
        view
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        bool _isGuardian;

        if (signature.length < 65)
            revert SSR__verifyGuardian__invalidSignature();

        (r, s, v) = splitSigs(signature, 0);

        // We first check if the guardian is a regular EOA ...
        address recovered = returnSigner(dataHash, r, s, v);

        if (guardians[recovered] != address(0)) {
            _isGuardian = true;
        } else {
            // Else, the guardian can be a smart contract wallet ...
            // Each wallet can pack their signatures in different ways,
            // so we need to send the payload ...
            address[] memory _guardians = getGuardians();

            for (uint256 i = 0; i < guardianCount; ) {
                address guardian = _guardians[i];
                // We check if the guardian is a smart contract wallet ...
                if (guardian.code.length > 0) {
                    if (
                        IEIP1271(guardian).isValidSignature(
                            dataHash,
                            signature
                        ) == 0x1626ba7e
                    ) _isGuardian = true;
                }
                unchecked {
                    // Won't overflow ...
                    ++i;
                }
            }
        }
        if (!_isGuardian) revert SSR__verifyGurdian__notGuardian();
    }

    /**
     * @dev Verifies that the signatures correspond to the owner and guardian.
     * The first signature needs to match the owner.
     */
    function verifyOwnerAndGuardian(bytes32 dataHash, bytes calldata signatures)
        internal
        view
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // The guardian can be an EOA or smart contract wallet ...
        if (signatures.length < 130)
            revert SSR__verifyOwnerAndGuardian__invalidSignature();

        // The first signer needs to be the owner ...
        (r, s, v) = splitSigs(signatures, 0);
        address _isOwner = returnSigner(dataHash, r, s, v);
        if (_isOwner != owner) revert SSR__verifyOwnerAndGuardian__notOwner();

        // The second signer needs to be the guardian ...
        // We first check if the guardian is a regular EOA ...
        address recoveredGuardian;
        bool _isGuardian;
        recoveredGuardian = returnSigner(dataHash, r, s, v);
        if (guardians[recoveredGuardian] != address(0)) {
            _isGuardian = true;
        } else {
            // Else, the guardian can be a smart contract wallet ...
            // Each wallet can pack their signatures in different ways,
            // so we need to send the payload ...
            address[] memory _guardians = getGuardians();

            for (uint256 i = 0; i < guardianCount; ) {
                address guardian = _guardians[i];
                // We check if the guardian is a smart contract wallet ...
                if (guardian.code.length > 0) {
                    if (
                        IEIP1271(guardian).isValidSignature(
                            dataHash,
                            signatures
                        ) == 0x1626ba7e
                    ) _isGuardian = true;
                }
                unchecked {
                    // Won't overflow ...
                    ++i;
                }
            }
        }
        if (!_isGuardian) revert SSR__verifyOwnerAndGuardian__notGuardian();
    }

    /**
     * @dev Verifies that the signatures correspond to the recovery owner and guardian.
     * The first signature needs to match the recovery owner.
     */
    function verifyRecoveryOwnerAndGurdian(
        bytes32 dataHash,
        bytes calldata signatures
    ) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // The guardian can be an EOA or smart contract wallet ...
        if (signatures.length < 130)
            revert SSR__verifyRecoveryOwnerAndGurdian__invalidSignature();

        // The first signer needs to be the recovery owner ...
        (r, s, v) = splitSigs(signatures, 0);
        address _isRecoveryOwner = returnSigner(dataHash, r, s, v);
        if (_isRecoveryOwner != recoveryOwner)
            revert SSR__verifyRecoveryOwnerAndGurdian__notRecoveryOwner();

        // The second signer needs to be the guardian ...
        // We first check if the guardian is a regular EOA ...
        bool _isGuardian;
        address recoveredGuardian = returnSigner(dataHash, r, s, v);
        if (guardians[recoveredGuardian] != address(0)) {
            _isGuardian = true;
        } else {
            // Else, the guardian can be a smart contract wallet ...
            // Each wallet can pack their signatures in different ways,
            // so we need to send the payload ...
            address[] memory _guardians = getGuardians();

            for (uint256 i = 0; i < guardianCount; ) {
                address guardian = _guardians[i];
                // We check if the guardian is a smart contract wallet ...
                if (guardian.code.length > 0) {
                    if (
                        IEIP1271(guardian).isValidSignature(
                            dataHash,
                            signatures
                        ) == 0x1626ba7e
                    ) _isGuardian = true;
                }
                unchecked {
                    // Won't overflow ...
                    ++i;
                }
            }
        }
        if (!_isGuardian)
            revert SSR__verifyRecoveryOwnerAndGurdian__notGuardian();
    }

    /**
     * @dev Verifies that the signatures correspond to the owner and recovery owner.
     * The first signature needs to match the owner.
     */
    function verifyOwnerAndRecoveryOwner(
        bytes32 dataHash,
        bytes memory signatures
    ) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Both, the owner and recovery owner must be EOA's ....
        if (signatures.length != 130)
            revert SSR__verifyOwnerAndRecoveryOwner__invalidSignature();

        // The first signer needs to be the owner ...
        (r, s, v) = splitSigs(signatures, 0);
        address _isOwner = returnSigner(dataHash, r, s, v);
        if (_isOwner != owner)
            revert SSR__verifyOwnerAndRecoveryOwner__notOwner();

        // The second signer needs to be the recovery owner ...
        (r, s, v) = splitSigs(signatures, 1);
        address _isRecoveryOwner = returnSigner(dataHash, r, s, v);
        if (_isRecoveryOwner != recoveryOwner)
            revert SSR__verifyOwnerAndRecoveryOwner__notRecoveryOwner();
    }
}
