// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// OpenZeppelin
import "./ECDSA.sol";

// Local imports - Structs
import "./AccessTypes.sol";

// Local imports - Constants
import "./SignatureConstants.sol";

// Local imports - Errors
import "./SignatureErrors.sol";

// Local imports - Storages
import "./LibAccessControl.sol";

library SignatureService {
    // const
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @dev Verify if given signature is signed by correct signer.
    /// @param _message Hash message
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function verifySignature(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) internal view {
        // signer of message
        address signer_ = recoverSigner(_message, _v, _r, _s);

        // validate signer
        if (!LibAccessControl.hasRole(AccessTypes.SIGNER_ROLE, signer_)) {
            revert SignatureErrors.IncorrectSigner(signer_);
        }
    }

    /// @dev Verify EIP-712 message sent.
    /// @param _nameHash Hash EIP-712 name
    /// @param _versionHash Hash EIP-712 version
    /// @param _rawMessage Hash message calculated "on-the-fly"
    /// @param _message Message sent in request
    function verifyMessage(bytes32 _nameHash, bytes32 _versionHash, bytes32 _rawMessage, bytes32 _message) internal view {
        // build domain separator
        bytes32 domainSeparatorV4_ = keccak256(
            abi.encode(SignatureConstants.EIP712_DOMAIN_TYPEHASH, _nameHash, _versionHash, block.chainid, address(this))
        );

        // construct EIP712 message
        bytes32 toVerify_ = ECDSA.toTypedDataHash(domainSeparatorV4_, _rawMessage);

        // verify computation against original
        if (toVerify_ != _message) {
            revert SignatureErrors.InvalidMessage(toVerify_, _message);
        }
    }

    function hashToMessage(bytes32 _nameHash, bytes32 _versionHash, bytes32 _rawMessage) internal view returns (bytes32) {
        // return
        return hashToMessage(_nameHash, _versionHash, _rawMessage, address(this));
    }

    function hashToMessage(
        bytes32 _nameHash,
        bytes32 _versionHash,
        bytes32 _rawMessage,
        address _contractAddress
    ) internal view returns (bytes32) {
        // build domain separator
        bytes32 domainSeparatorV4_ = keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, _nameHash, _versionHash, block.chainid, _contractAddress));

        // construct EIP712 message
        return ECDSA.toTypedDataHash(domainSeparatorV4_, _rawMessage);
    }

    /// @dev Allows to return signer of the signature.
    /// @param _data Message sent in request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    /// @return Signer of the message
    function recoverSigner(bytes32 _data, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        // recover EIP712 signer using provided vrs
        address signer_ = ECDSA.recover(_data, _v, _r, _s);

        // return signer
        return signer_;
    }
}
