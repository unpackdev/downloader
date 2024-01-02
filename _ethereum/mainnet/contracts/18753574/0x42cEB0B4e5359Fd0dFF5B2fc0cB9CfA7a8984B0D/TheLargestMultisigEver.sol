// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @dev Defines call parameters for transactions 
struct Call {
    uint256 callIndex;
    address to;
    uint256 value;
    bytes data;
}

/**
 * @title TheLargestMultisigEver
 * @author 0xth0mas
 * @notice This multisig wallet is a public multisig that allows any Ethereum
 *         address to be a signer on a transaction
 */
contract TheLargestMultisigEver {

    /// @dev Thrown when non-address(this) attempts to call external functions that must be called from address(this)
    error InvalidCaller();

    /// @dev Thrown when the call results in a revert
    error CallFailed(); 

    /// @dev Thrown when signatures are submitted for a call index greater than the current call index or when a call has already been executed
    error InvalidCall();

    /// @dev Thrown when the minimum signature threshold is being set to zero
    error NotEnoughSigners();

    /// @dev Thrown when a signature length is not 65 bytes
    error InvalidSignature();

    /// @dev Thrown when attempting to set minimum signatures greater than number of possible Ethereum addresses
    error CannotExceedPossibleAddresses();

    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant CALL_TYPEHASH = keccak256(
        "Call(uint256 callIndex,address to,uint256 value,bytes data)"
    );

    bytes32 public immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    string private constant _name = "TheLargestMultisigEver";
    string private constant _version = "1.0";

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    /// @dev mapping of proposed calls to their index
    mapping(uint256 callIndex => Call) public proposedCalls;

    /// @dev mapping of calls that have been executed
    mapping(uint256 callIndex => bool executed) public callExecuted;

    /// @dev bitmap to track signers that have already approved a transaction
    mapping(uint256 callIndex => mapping(uint256 bucket => uint256 signed)) public callSigners;

    /// @dev mapping of number of signers for a proposed call
    mapping(uint256 callIndex => uint256 signerCount) public callSignerCount;

    /// @dev the minimum number of valid signatures to execute a transaction
    uint168 public minimumSignatures;

    /// @dev the next index for a proposed call to be executed by the multisig
    uint88 public nextCallIndex;

    constructor() payable {
        _hashedName = keccak256(bytes(_name));
        _hashedVersion = keccak256(bytes(_version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);

        callExecuted[0] = true;
        nextCallIndex = 1;
        
        minimumSignatures = 1;
    }

    /**
     * @notice Propose a transaction to be made by the multisig.
     * @param call struct containing the details of the call transaction to execute
     * @return callIndex the index of the call that will need to be signed by at least
     *                   the minimum number of signers to be executed
     */
    function proposeCall(Call calldata call) external returns(uint256 callIndex) {
        callIndex = nextCallIndex;
        proposedCalls[callIndex] = call;
        proposedCalls[callIndex].callIndex = callIndex;
        unchecked {
            ++nextCallIndex;
        }
    }

    /**
     * @notice Validates signatures for a proposed call and increments signer count.
     *         If the proposed call has enough signatures it will be executed.
     */
    function submitSignatures(uint256 callIndex, bytes[] calldata signatures) external {
        if(callIndex >= nextCallIndex || callExecuted[callIndex]) revert InvalidCall();

        Call memory call = proposedCalls[callIndex];
        bytes32 callDigest = _getCallSignatureDigest(_getCallHash(call));

        uint256 validSignatures = callSignerCount[callIndex];

        mapping(uint256 bucket => uint256 signed) storage callIndexSigners = callSigners[callIndex];

        for(uint256 signatureIndex;signatureIndex < signatures.length;) {
            address signer = _recover(callDigest, signatures[signatureIndex]);

            uint256 signerInt = uint256(uint160(signer));
            uint256 bucket = signerInt / 256;
            uint256 slot = signerInt % 256;
            uint256 bucketValue = callIndexSigners[bucket];
            if((bucketValue >> slot) & 0x01 == 0) {
                callIndexSigners[bucket] = bucketValue | (1 << slot);
                unchecked {
                    ++validSignatures;
                }
            }

            unchecked {
                ++signatureIndex;
            }
        }

        callSignerCount[callIndex] = validSignatures;

        if(validSignatures >= minimumSignatures) {
            if(_execute(call.to, call.value, call.data)) { 
                callExecuted[callIndex] = true;
            } else {
                revert CallFailed();
            }
        }

    }

    /**
     * @notice Sets the minimum number of signatures to execute a transaction
     * @dev This enforces minimum signatures > 0 and current signers > minimum
     * @param _minimumSignatures the threshold of valid signatures to execute a transaction
     */
    function setMinimumSignatures(uint256 _minimumSignatures) external {
        if(msg.sender != address(this)) revert InvalidCaller();

        if(_minimumSignatures == 0) revert NotEnoughSigners();
        if(_minimumSignatures > 2**160) revert CannotExceedPossibleAddresses();

        minimumSignatures = uint160(_minimumSignatures);
    }

    function _execute(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        (success, ) = to.call{value: value}(data);
    }

    function _getCallSignatureDigest(bytes32 callHash) internal view returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), callHash)
        );
    }

    function _getCallHash(
        Call memory call
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded = abi.encode(
            CALL_TYPEHASH,
            call.callIndex,
            call.to,
            call.value,
            keccak256(call.data)
        );
        hash = keccak256(encoded);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparator() private view returns (bytes32 separator) {
        separator = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildDomainSeparator();
        }
    }

    /**
     *  @dev Returns if the cached domain separator has been invalidated.
     */ 
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        address cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(
        bytes32 hash,
        bytes calldata sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            revert InvalidSignature();
        }

        // Divide the signature in r, s and v variables
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }

        return ecrecover(hash, v, r, s);
    }

    fallback() external payable { }
    receive() external payable { }
}