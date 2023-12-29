// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "./ECDSA.sol";

abstract contract MultiSig {
    enum Errors {
        NoError,
        SignatureError,
        DuplicatedSigner,
        SignerNotInCommittee
    }

    mapping(address signer => bool active) public signers;
    uint64 public signerSize;
    uint64 public quorum;

    event UpdateSigner(address _signer, bool _active);
    event UpdateQuorum(uint64 _quorum);

    modifier onlySigner() {
        require(signers[msg.sender], "MultiSig: caller must be signer");
        _;
    }

    constructor(address[] memory _signers, uint64 _quorum) {
        require(_signers.length >= _quorum && _quorum > 0, "MultiSig: signers too few");

        address lastSigner = address(0);
        for (uint i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer > lastSigner, "MultiSig: signers not sorted"); // to ensure no duplicates
            signers[signer] = true;
            lastSigner = signer;
        }
        signerSize = uint64(_signers.length);
        quorum = _quorum;
    }

    function _setSigner(address _signer, bool _active) internal {
        require(signers[_signer] != _active, "MultiSig: signer already in that state");
        signers[_signer] = _active;
        signerSize = _active ? signerSize + 1 : signerSize - 1;
        require(signerSize >= quorum, "MultiSig: committee size < threshold");
        emit UpdateSigner(_signer, _active);
    }

    function _setQuorum(uint64 _quorum) internal {
        require(_quorum <= signerSize && _quorum > 0, "MultiSig: invalid quorum");
        quorum = _quorum;
        emit UpdateQuorum(_quorum);
    }

    function verifySignatures(bytes32 _hash, bytes calldata _signatures) public view returns (bool, Errors) {
        if (_signatures.length != uint(quorum) * 65) {
            return (false, Errors.SignatureError);
        }

        bytes32 messageDigest = _getEthSignedMessageHash(_hash);

        address lastSigner = address(0); // There cannot be a signer with address 0.
        for (uint i = 0; i < quorum; i++) {
            bytes calldata signature = _signatures[i * 65:(i + 1) * 65];
            (address currentSigner, ECDSA.RecoverError error) = ECDSA.tryRecover(messageDigest, signature);

            if (error != ECDSA.RecoverError.NoError) return (false, Errors.SignatureError);
            if (currentSigner <= lastSigner) return (false, Errors.DuplicatedSigner); // prevent duplicate signatures
            if (!signers[currentSigner]) return (false, Errors.SignerNotInCommittee); // signature is not in committee
            lastSigner = currentSigner;
        }
        return (true, Errors.NoError);
    }

    function _getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}
