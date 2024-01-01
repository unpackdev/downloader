// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./IMpOwnable.sol";


abstract contract MultipartyCommons is IMpOwnable {
    bytes32 immutable internal VOTE_TYPE_HASH;
    bytes32 internal DOMAIN_SEPARATOR;

    mapping(uint => bool) public usedSalt;

    // Self-calls are used to engage builtin deserialization facility (abi parsing) and not parse args ourselves
    modifier selfCall virtual {
        require(msg.sender == address(this), "MP: NO_ACCESS");
        _;
    }

    // Checks if a privileged call can be applied
    modifier applicable(uint salt, uint deadline) virtual {
        require(getTimeNow() <= deadline, "MP: DEADLINE");
        require(!usedSalt[salt], "MP: DUPLICATE");
        usedSalt[salt] = true;
        _;
    }

    constructor(address verifyingContract, uint256 chainId) {
        require(verifyingContract != address(0) && chainId != 0, 'MP: Invalid domain parameters');
        VOTE_TYPE_HASH = keccak256("Vote(bytes calldata)");
        setDomainSeparator(chainId, verifyingContract);
    }

    /**
     * @notice DOMAIN_SEPARATOR setter.
     * @param chainId Chain id of the verifying contract
     * @param verifyingContract Address of the verifying contract
     */
    function setDomainSeparator(uint256 chainId, address verifyingContract) internal {
        DOMAIN_SEPARATOR = buildDomainSeparator(chainId, verifyingContract);
    }

    function buildDomainSeparator(uint256 chainId, address verifyingContract) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Multidata.Multiparty.Protocol")),
                keccak256(bytes("1")),
                chainId,
                verifyingContract
            )
        );
    }

    /**
     * @notice Performs privileged call to the contract.
     * @param privilegedCallData Method calldata
     * @param v Signature v for the call
     * @param r Signature r for the call
     * @param s Signature s for the call
     */
    function privilegedCall(bytes calldata privilegedCallData, uint8 v, bytes32 r, bytes32 s) external
    {
        checkMessageSignature(keccak256(abi.encode(VOTE_TYPE_HASH, keccak256(privilegedCallData))), v, r, s);

        (bool success, bytes memory returnData) = address(this).call(privilegedCallData);
        if (!success) {
            revert(string(returnData));
        }
    }

    /**
     * @notice Checks the message signature.
     * @param hashStruct Hash of a message struct
     * @param v V of the message signature
     * @param r R of the message signature
     * @param s S of the message signature
     */
    function checkMessageSignature(bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal virtual view {
        require(isMessageSignatureValid(hashStruct, v, r, s), "MP: NO_ACCESS");
    }

    function isMessageSignatureValid(bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal virtual view returns (bool) {
        return ECDSA.recover(generateMessageHash(hashStruct), v, r, s) == mpOwner();
    }

    function checkMessageSignatureForDomain(bytes32 domainSeparator, bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal virtual view {
        require(ECDSA.recover(generateMessageHashForDomain(domainSeparator, hashStruct), v, r, s) == mpOwner(), "MP: NO_ACCESS");
    }

    /**
     * @notice Returns hash of the message for the hash of the struct.
     * @param hashStruct Hash of a message struct
     */
    function generateMessageHash(bytes32 hashStruct) internal view returns (bytes32) {
        return generateMessageHashForDomain(DOMAIN_SEPARATOR, hashStruct);
    }

    function generateMessageHashForDomain(bytes32 domainSeparator, bytes32 hashStruct) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                hashStruct
            )
        );
    }

    /**
     * @notice Returns current chain time in unix ts.
     */
    function getTimeNow() virtual internal view returns (uint32) {
        return uint32(block.timestamp);
    }

    // @inheritdoc IMpOwnable
    function ownerMultisignature() public view virtual override returns (OwnerMultisignature memory);

    // @inheritdoc IMpOwnable
    function mpOwner() public view virtual override returns (address);
}
