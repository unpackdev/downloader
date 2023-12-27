// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Safe.sol";
import "./EIP712DomainSeparator.sol";

/// @title WaymontSafePolicyGuardianSigner
/// @notice Smart contract signer (via ERC-1271) for Safes wrapping an EOA and supporting changing the EOA or bypassing this signer (for all Safes) from a global manager address as well as bypassing this signer after a timelock on a specific Safe.
/// This contract is meant to be used with Safe contracts v1.4.1 (https://github.com/safe-global/safe-contracts/tree/v1.4.1). It can also be used with v1.4.0.
contract WaymontSafePolicyGuardianSigner is EIP712DomainSeparator {
    /// @dev Typehash for `queueDisablePolicyGuardian`: `keccak256("QueueDisablePolicyGuardian(uint256 nonce)")`.
    bytes32 private constant QUEUE_DISABLE_POLICY_GUARDIAN_TYPEHASH = 0xd5fa5ce164fba34243c3b3b9c5346acc2eae6f31655b86516d465566d0ba53f7;

    /// @dev Typehash for `unqueueDisablePolicyGuardian`: `keccak256("UnqueueDisablePolicyGuardian(uint256 nonce)")`.
    bytes32 private constant UNQUEUE_DISABLE_POLICY_GUARDIAN_TYPEHASH = 0x16dda714d491dced303c8770c04d1539fd0000764e8745d3fe40945bb0d59dcf;

    /// @dev Typehash for `disablePolicyGuardian`: `keccak256("DisablePolicyGuardian(uint256 nonce)")`.
    bytes32 private constant DISABLE_POLICY_GUARDIAN_TYPEHASH = 0x1fa738809572ae202e6e8b28ae7d08f5972c3ae85e70f8bc386515bb47925975;

    /// @notice Default policy guardian timelock (in seconds): 2 weeks.
    uint256 public constant DEFAULT_POLICY_GUARDIAN_TIMELOCK = 2 weeks;

    /// @notice Minimum policy guardian timelock (in seconds): 15 minutes.
    uint256 public constant MIN_POLICY_GUARDIAN_TIMELOCK = 15 minutes;

    /// @notice Maximum policy guardian timelock (in seconds): 180 days.
    uint256 public constant MAX_POLICY_GUARDIAN_TIMELOCK = 180 days;

    /// @notice Time to expiry after a signature has been queued (in seconds): 1 week.
    uint256 public constant QUEUED_SIGNATURE_EXPIRATION = 1 weeks;

    /// @notice The primary policy guardian address.
    /// WARNING: If this variable is set to the zero address, wallets will not require signatures from either policy guardian address--so do NOT set this variable to the zero address unless you are sure you want to allow all transactions to bypass the policy guardian's firewall.
    /// The (primary or secondary) policy guardian must sign all transactions for a `Wallet`, unless the policy guardian is deactivated on a `Wallet` or if the primary `policyGuardian` is set to the zero address here, in which case all transactinos will bypass the policy guardian's firewall.
    /// The (primary or secondary) policy guardian can act as off-chain transaction policy node(s) permitting realtime/AI-based fraud detection, symmetric/access-token-based authentication mechanisms, and/or instant onboarding to the Waymont chain.
    /// The (primary or secondary) policy guardian can be disabled/enabled via a user-specified timelock on the `Wallet`.
    address public policyGuardian;

    /// @notice The secondary policy guardian address.
    /// WARNING: Even if the secondary guardian address is set, if the primary guardian address is not set, the `Wallet` contract does not require a signature from either policy guardian address.
    /// The secondary policy guardian is used as a fallback guardian.
    /// If using a secondary policy guardian, ideally, it is the less-used of the two guardians to conserve some gas.
    address public secondaryPolicyGuardian;

    /// @notice Whether or not the policy guardian has been permanently disabled across all wallets.
    bool public policyGuardianPermanentlyDisabled;

    /// @notice The pending policy guardian manager.
    address public pendingPolicyGuardianManager;

    /// @notice The policy guardian manager.
    address public policyGuardianManager;

    /// @notice For each `Safe`, custom timelock after which the policy guardian can be disabled (in seconds). If not set for a specific `Safe`, defaults to `DEFAULT_POLICY_GUARDIAN_TIMELOCK`.
    mapping(Safe => uint256) public customPolicyGuardianTimelocks;

    /// @notice For each `Safe`, whether or not the policy guardian is disabled.
    mapping(Safe => bool) public policyGuardianDisabled;

    /// @notice For each safe, last timestamp disabling the policy guardian was queued/requested.
    mapping(Safe => uint256) public disablePolicyGuardianQueueTimestamps;

    /// @notice For each safe, incremental nonce to prevent signature reuse on this contract.
    mapping(Safe => uint256) public nonces;

    /// @dev Temporarily approved data hash.
    bytes32 internal _tempApprovedDataHash;

    /// @notice Event emitted when the primary policy guardian is changed.
    event PolicyGuardianChanged(address _policyGuardian);

    /// @notice Event emitted when the policy guardian is disabled globally.
    /// @param permanently Whether or not the policy guardian was globally disabled permanently (if not, if it can be re-enabled later on).
    event PolicyGuardianDisabledGlobally(bool permanently);

    /// @notice Event emitted when the secondary policy guardian is changed.
    event SecondaryPolicyGuardianChanged(address _policyGuardian);

    /// @notice Event emitted when the policy guardian manager is changed.
    event PolicyGuardianManagerChanged(address _policyGuardianManager);

    /// @notice Event emitted when the pending policy guardian manager is changed.
    event PendingPolicyGuardianManagerChanged(address _pendingPolicyGuardianManager);

    /// @notice Event emitted when queuing the action of disabling the policy guardian on a `Safe`.
    /// Useful for sending security notifications to `Safe` owners if the policy guardian cannot find record of itself sending the transaction hash associated with a `DisablePolicyGuardianQueued` event.
    event DisablePolicyGuardianQueued(Safe indexed safe);

    /// @notice Event emitted when unqueuing the action of disabling the policy guardian on a `Safe`.
    event DisablePolicyGuardianUnqueued(Safe indexed safe);

    /// @notice Event emitted when executing the action of disabling the policy guardian on a `Safe`.
    event PolicyGuardianDisabledOnSafe(Safe indexed safe, bool withoutPolicyGuardian);

    /// @notice Event emitted when the policy guardian timelock is changed for a `Safe`.
    event PolicyGuardianTimelockChanged(Safe indexed safe, uint256 policyGuardianTimelock);

    /// @dev Constructor to initialize the contract by setting the policy guardian manager.
    constructor(address _policyGuardianManager) {
        require(_policyGuardianManager != address(0), "Invalid policy guardian manager.");
        policyGuardianManager = _policyGuardianManager;
        emit PolicyGuardianManagerChanged(_policyGuardianManager);
    }

    /// @dev Access control for the policy guardian manager.
    modifier onlyPolicyGuardianManager() {
        require(msg.sender == policyGuardianManager, "Sender is not the policy guardian manager.");
        _;
    }

    /// @notice Sets the primary policy guardian address.
    function setPolicyGuardian(address _policyGuardian) external onlyPolicyGuardianManager {
        require(!policyGuardianPermanentlyDisabled, "Policy guardian has been permanently disabled.");
        require(_policyGuardian != address(0), "Cannot set policy guardian to the zero address. Use the disablePolicyGuardianGlobally function instead.");
        policyGuardian = _policyGuardian;
        emit PolicyGuardianChanged(_policyGuardian);
    }

    /// @notice Sets the secondary policy guardian address.
    /// WARNING: Even if the secondary guardian address is set, if the primary guardian address is not set, the `Wallet` contract will not require signatures from either policy guardian address.
    function setSecondaryPolicyGuardian(address _policyGuardian) external onlyPolicyGuardianManager {
        secondaryPolicyGuardian = _policyGuardian;
        emit SecondaryPolicyGuardianChanged(_policyGuardian);
    }
    
    /// @notice Globally disables the policy guardian: i.e., makes it so that any and ALL wallets will NOT require signatures from either policy guardian address.
    /// WARNING: Do NOT call this function unless you are sure you want to allow all transactions through the policy guardian's firewall on ALL `Safe`s using this `WaymontSafePolicyGuardianSigner`.
    function disablePolicyGuardianGlobally() external onlyPolicyGuardianManager {
        require(policyGuardian != address(0), "Policy guardian already disabled.");
        policyGuardian = address(0);
        emit PolicyGuardianChanged(address(0));
        emit PolicyGuardianDisabledGlobally(false); // Emit with flag `permanently` equal to `false` since the policy guardian can be re-enabled later on
    }

    /// @notice Permanently disables the policy guardian on all wallets.
    /// WARNING: Do NOT call this function unless you are sure you want to PERMANENTLY allow all transactions through the policy guardian's firewall on ALL `Safe`s using this `WaymontSafePolicyGuardianSigner`.
    function disablePolicyGuardianPermanently() external onlyPolicyGuardianManager {
        require(!policyGuardianPermanentlyDisabled, "Policy guardian already permanently disabled.");
        policyGuardianPermanentlyDisabled = true;
        policyGuardian = address(0);
        emit PolicyGuardianChanged(address(0));
        emit PolicyGuardianDisabledGlobally(true); // Emit with flag `permanently` equal to `true` since the policy guardian can NOT be re-enabled later on
    }

    /// @notice Sets the pending policy guardian manager.
    function setPendingPolicyGuardianManager(address _policyGuardianManager) external onlyPolicyGuardianManager {
        pendingPolicyGuardianManager = _policyGuardianManager;
        emit PendingPolicyGuardianManagerChanged(_policyGuardianManager);
    }

    /// @notice Accepts the policy guardian manager role.
    function acceptPolicyGuardianManager() external {
        require(msg.sender == pendingPolicyGuardianManager, "Sender is not the pending policy guardian manager.");
        policyGuardianManager = msg.sender;
        pendingPolicyGuardianManager = address(0);
        emit PolicyGuardianManagerChanged(msg.sender);
    }

    /// @dev Validates `signatures` on `underlyingTypehash`.
    /// @param signatures Signatures from `threshold - 1` signers (excluding the policy guardian).
    function _validateSignatures(Safe safe, bytes32 underlyingTypehash, bytes memory signatures) internal {
        // Generate underlying hash
        bytes32 underlyingHash = keccak256(abi.encode(underlyingTypehash, safe, nonces[safe]++));

        // Generate overlying signed data
        bytes memory data = abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), underlyingHash);

        // Validate threshold
        require(safe.getThreshold() > 1, "Cannot disable the policy guardian since the threshold on the Safe is one.");

        // Mark data as signed so the call inside `safe.checkSignatures` to `this.isValidSignature` will succeed
        _tempApprovedDataHash = keccak256(data);

        // Check that `data` has been signed by `signatures` across all signers including this contract
        safe.checkSignatures(keccak256(data), data, signatures);

        // Delete temporary storage for gas refund
        delete _tempApprovedDataHash;
    }

    /// @notice Returns the policy guardian timelock for `safe`.
    /// @dev When `customPolicyGuardianTimelocks[safe]` is set to 0, the default timelock is used for `safe`.
    function getPolicyGuardianTimelock(Safe safe) public view returns (uint256 policyGuardianTimelock) {
        policyGuardianTimelock = customPolicyGuardianTimelocks[safe];
        if (policyGuardianTimelock == 0) policyGuardianTimelock = DEFAULT_POLICY_GUARDIAN_TIMELOCK;
    }

    /// @notice Change the policy guardian timelock.
    /// Also enables validation of the policy guardian signature (if not already enabled). 
    /// Off chain policy guardian logic: if changing the timelock when the policy guardian is already enabled, require that the user waits for the old timelock to pass after queueing it off-chain.
    /// @param policyGuardianTimelock The desired timelock required to disable the policy guardian without the policy guardian's signature.
    function setPolicyGuardianTimelock(uint256 policyGuardianTimelock) external {
        require(policyGuardianTimelock >= MIN_POLICY_GUARDIAN_TIMELOCK, "Policy guardian timelock must be at least 15 minutes. Call disablePolicyGuardian to disable it.");
        require(policyGuardianTimelock <= MAX_POLICY_GUARDIAN_TIMELOCK, "Policy guardian timelock cannot be more than 180 days.");
        Safe safe = Safe(payable(msg.sender));
        customPolicyGuardianTimelocks[safe] = policyGuardianTimelock;
        policyGuardianDisabled[safe] = false;
        disablePolicyGuardianQueueTimestamps[safe] = 0;
        emit PolicyGuardianTimelockChanged(safe, policyGuardianTimelock);
    }

    /// @notice Disable validation of the policy guardian signature.
    /// WARNING: Do NOT call this function unless you are sure you want to allow all transactions from `Safe(msg.sender)` through the policy guardian's firewall.
    /// Off chain policy guardian logic: require that the user waits for the old timelock to pass after queueing it off-chain.
    function disablePolicyGuardian() external {
        Safe safe = Safe(payable(msg.sender));
        policyGuardianDisabled[safe] = true;
        disablePolicyGuardianQueueTimestamps[safe] = 0;
        emit PolicyGuardianDisabledOnSafe(safe, false);
    }

    /// @notice Queues a timelocked action.
    /// @param signatures Signatures from `threshold - 1` signers (excluding the policy guardian).
    function queueDisablePolicyGuardian(Safe safe, bytes calldata signatures) external {
        // Ensure not already disabled
        require(!policyGuardianDisabled[safe], "Policy guardian already disabled.");

        // Validate signatures
        _validateSignatures(safe, QUEUE_DISABLE_POLICY_GUARDIAN_TYPEHASH, signatures);

        // Mark down queue timestamp
        disablePolicyGuardianQueueTimestamps[safe] = block.timestamp;

        // Emit event
        emit DisablePolicyGuardianQueued(safe);
    }

    /// @notice Unqueues a timelocked action.
    /// @param signatures Signatures from `threshold - 1` signers (excluding the policy guardian).
    function unqueueDisablePolicyGuardian(Safe safe, bytes calldata signatures) external {
        // Ensure not already disabled
        require(!policyGuardianDisabled[safe], "Policy guardian already disabled.");

        // Validate signatures
        _validateSignatures(safe, UNQUEUE_DISABLE_POLICY_GUARDIAN_TYPEHASH, signatures);

        // Reset queue timestamp
        disablePolicyGuardianQueueTimestamps[safe] = 0;

        // Emit event
        emit DisablePolicyGuardianUnqueued(safe);
    }

    /// @notice Disable the policy guardian (by setting `policyGuardianDisabled[safe] = true`) after the on-chain timelock has passed (without needing a signature from the policy guardian).
    /// Requires that the user waits for the old timelock to pass (after calling `queueAction`).
    /// @param signatures Signatures from `threshold - 1` signers (excluding the policy guardian).
    function disablePolicyGuardianWithoutPolicyGuardian(Safe safe, bytes calldata signatures) external {
        // Ensure not already disabled
        require(!policyGuardianDisabled[safe], "Policy guardian already disabled.");

        // Validate signatures
        _validateSignatures(safe, DISABLE_POLICY_GUARDIAN_TYPEHASH, signatures);

        // Check timelock
        uint256 timestamp = disablePolicyGuardianQueueTimestamps[safe];
        require(timestamp > 0, "Action not queued.");
        uint256 minExecutionTimestamp = timestamp + getPolicyGuardianTimelock(safe);
        require(block.timestamp >= minExecutionTimestamp, "Timelock not satisfied.");
        require(block.timestamp <= minExecutionTimestamp + QUEUED_SIGNATURE_EXPIRATION, "Queued signatures are only usable for 1 week until they expire.");

        // Disable it
        policyGuardianDisabled[safe] = true;

        // Emit event
        emit PolicyGuardianDisabledOnSafe(safe, true);
    }

    /// @notice Signature validation function used by the `Safe` overlying this contract to validate underlying signers attached to this contract.
    /// @param _data Data signed in `_signature`.
    /// @param _signature Signature byte array associated with `_data`.
    /// @dev MUST return the bytes4 magic value 0x20c13b0b when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    /// MUST allow external calls.
    function isValidSignature(bytes calldata _data, bytes memory _signature) external view returns (bytes4) {
        // Require signature is 65 bytes
        require(_signature.length == 65, "Invalid signature length.");

        // Decode signature from bytes
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Recover signer from signature
        bytes32 dataHash = keccak256(_data);
        address signer = ecrecover(dataHash, v, r, s);

        // Check that signer is policy guardian or that policy guardian is disabled (and return success if so)
        address _policyGuardian = policyGuardian;
        if (signer == _policyGuardian || (signer == secondaryPolicyGuardian && signer != address(0)) || _policyGuardian == address(0) || policyGuardianPermanentlyDisabled || policyGuardianDisabled[Safe(payable(msg.sender))]) return bytes4(0x20c13b0b);
        
        // Otherwise, check `_tempApprovedDataHash` (and return success if equal)
        if (dataHash != 0 && _tempApprovedDataHash == dataHash) return bytes4(0x20c13b0b);

        // Return failure by default
        revert("Invalid policy guardian signature.");
    }
}
