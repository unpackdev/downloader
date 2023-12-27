// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Safe.sol";
import "./EIP712DomainSeparator.sol";
import "./CheckSignatures.sol";
import "./Enum.sol";

import "./WaymontSafeFactory.sol";
import "./WaymontSafePolicyGuardianSigner.sol";

/// @title WaymontSafeTimelockedRecoveryModule
/// @notice Safe module supporting timelocked recovery by an alternate group of signers.
/// This contract is meant to be used with Safe contracts v1.4.1 (https://github.com/safe-global/safe-contracts/tree/v1.4.1). It can also be used with v1.4.0.
contract WaymontSafeTimelockedRecoveryModule is EIP712DomainSeparator, CheckSignatures {
    /// @dev Typehash for `queueTransaction`: `keccak256("QueueSignature(bytes signature)")`.
    bytes32 private constant QUEUE_SIGNATURE_TYPEHASH = 0x56f7b592467518044b02545f1b4518cd51c746d04978afb6a3b9d05895cb79cf;

    /// @dev Typehash for `execTransaction`: `keccak256("ExecTransaction(address safe,uint256 nonce,address to,uint256 value,bytes data,uint8 operation)")`.
    bytes32 private constant EXEC_TRANSACTION_TYPEHASH = 0x017ac7ed7bb44ab92aef10c445ff46b9a95c18bfa2bf271178886356daa01e9c;

    /// @dev Minimum signing timelock value (in seconds): 15 minutes.
    uint256 public constant MIN_SIGNING_TIMELOCK = 15 minutes;

    /// @notice Time to expiry after a signature has been queued (in seconds): 1 week.
    uint256 public constant QUEUED_SIGNATURE_EXPIRATION = 1 weeks;

    /// @notice Timelock for signers on this contract to submit signed transactions.
    uint256 public signingTimelock;

    /// @notice Address of the `WaymontSafeFactory` contract.
    WaymontSafeFactory public waymontSafeFactory;

    /// @notice Address of the `WaymontSafePolicyGuardianSigner` contract.
    WaymontSafePolicyGuardianSigner public policyGuardianSigner;

    /// @notice Maps pending (queued) signature hashes to queue timestamps.
    mapping(bytes32 => uint256) public pendingSignatures;

    /// @notice Incremental nonce to prevent signature reuse on this contract.
    uint256 public nonce;

    /// @notice Event emitted when the underlying transcation succeeds in `WaymontSafeTimelockedRecoveryModule.execTransaction`.
    event ExecutionSuccess(bytes32 indexed txHash);

    /// @notice Event emitted when the underlying transcation fails in `WaymontSafeTimelockedRecoveryModule.execTransaction`.
    event ExecutionFailure(bytes32 indexed txHash);

    /// @dev Initializes the contract by setting the `Safe`, signers, threshold, and signing timelock.
    /// @param _safe The `Safe` of which this signer contract will be an owner.
    /// @param signers The signers underlying this signer contract.
    /// @param threshold The threshold required of signers underlying this signer contract.
    /// @param _signingTimelock Timelock for signers on this contract to submit signed transactions.
    /// @param _policyGuardianSigner Set to the `WaymontSafePolicyGuardianSigner` contract to validate the policy guardian's signature on recovery; to NOT validate the policy guardian's signature on recovery, set to the zero address.
    /// Can only be called once (because `setupOwners` can only be called once).
    function initialize(
        Safe _safe,
        address[] calldata signers,
        uint256 threshold,
        uint256 _signingTimelock,
        WaymontSafePolicyGuardianSigner _policyGuardianSigner
    ) external {
        // Input validation
        require(_safe.isModuleEnabled(address(this)), "The Safe does not have this Waymont module enabled.");
        require(_signingTimelock > MIN_SIGNING_TIMELOCK, "Signing timelock must be at least 15 minutes.");

        // Call `setupOwners` (can only be called once)
        setupOwners(signers, threshold);

        // Set the `Safe`, signingTimelock, `WaymontSafePolicyGuardianSigner`, and `WaymontSafeFactory`
        safe = _safe;
        signingTimelock = _signingTimelock;
        policyGuardianSigner = _policyGuardianSigner;
        waymontSafeFactory = WaymontSafeFactory(msg.sender);
    }

    /// @notice Executes a transaction.
    /// @param to Destination address.
    /// @param value Quantity of ETH in wei to be sent to the `to` address param.
    /// @param operation Whether the transaction is a call or a delegatecall.
    /// @param signatures Signatures from the recovery signer (and policy guardian signer if enabled).
    function execTransaction(address to, uint256 value, bytes calldata data, Enum.Operation operation, bytes calldata signatures, bytes calldata policyGuardianSignature) external {
        // Generate underlying hash
        bytes32 underlyingHash = keccak256(abi.encode(EXEC_TRANSACTION_TYPEHASH, safe, nonce++, to, value, keccak256(data), operation));

        // Generate overlying signed data and hash
        bytes memory txHashData = abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), underlyingHash);
        bytes32 txHash = keccak256(txHashData);

        // Check signatures
        checkSignatures(txHash, signatures);

        // Check signature from policy guardian (if applicable)
        if (address(policyGuardianSigner) != address(0)) require(policyGuardianSigner.isValidSignature(txHashData, policyGuardianSignature) == bytes4(0x20c13b0b), "Policy guardian signature validation failed.");

        // Check timelock
        for (uint256 i = 0; i < threshold; i++) {
            uint256 offset = i * 65;
            uint256 timestamp = pendingSignatures[keccak256(signatures[offset:offset + 65])];
            require(timestamp > 0, "Signature not queued.");
            uint256 minExecutionTimestamp = timestamp + signingTimelock;
            require(block.timestamp >= minExecutionTimestamp, "Timelock not satisfied.");
            require(block.timestamp <= minExecutionTimestamp + QUEUED_SIGNATURE_EXPIRATION, "Queued signatures are only usable for 1 week until they expire.");
        }

        // Execute transaction
        if (safe.execTransactionFromModule(to, value, data, operation)) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    /// @notice Event emitted when a signature is queued.
    event SignatureQueued(address signer, bytes32 signedDataHash);

    /// @notice Queues a timelocked signature.
    /// @dev No unqueue function because recovery signers can be removed from this module (and this module can be removed from the `Safe`).
    /// Access control prevents spamming of `SignatureQueued` events.
    /// @param underlyingHash Computed as `keccak256(abi.encode(EXEC_TRANSACTION_TYPEHASH, safe, nonce, to, value, data, operation))`.
    /// @param signature The signature on `keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), underlyingHash)))`. (Optionally prefix this hash to be signed with `"\x19Ethereum Signed Message:\n32"` before signing and add 4 to the `v` param.)
    /// @param policyGuardianSignature The signature from the policy guardian on `signature` (if applicable).
    function queueSignature(bytes32 underlyingHash, bytes calldata signature, bytes calldata policyGuardianSignature) external {
        // Generate overlying signed data hash
        bytes32 txHash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), underlyingHash));

        // Recover signer
        (uint8 v, bytes32 r, bytes32 s) = signatureSplit(signature, 0);
        address signer;
        if (v > 30) signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", txHash)), v - 4, r, s);
        else signer = ecrecover(txHash, v, r, s);

        // Validate signer is on the wallet
        require(isOwner(signer), "Invalid signature.");

        // Validate signature not already queued
        bytes32 signatureHash = keccak256(signature);
        require(pendingSignatures[signatureHash] == 0, "Signature already queued.");

        // Validate policy guardian signature (if applicable)
        if (address(policyGuardianSigner) != address(0)) {
            // Generate underlying hash
            bytes32 queueSignatureUnderlyingHash = keccak256(abi.encode(QUEUE_SIGNATURE_TYPEHASH, signatureHash));

            // Generate overlying signed data
            bytes memory queueSignatureMsgHashData = abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), queueSignatureUnderlyingHash);
            
            // Validate signature
            require(policyGuardianSigner.isValidSignature(queueSignatureMsgHashData, policyGuardianSignature) == bytes4(0x20c13b0b), "Policy guardian signature validation failed.");
        }

        // Queue signature
        pendingSignatures[signatureHash] = block.timestamp;

        // Emit events
        emit SignatureQueued(signer, txHash);
        waymontSafeFactory.emitSignatureQueued(signer, txHash);
    }
}
