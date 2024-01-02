// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract EIP712DomainVoting is Initializable {

    struct Upvote {
        address voter;
        uint256 proposalId;
        uint256 timestamp;
        uint256 nonce;
    }

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant UPVOTE_TYPEHASH = keccak256("UpVote(address voter,uint256 proposalId,uint256 timestamp,uint256 nonce)");

    bytes32 private DOMAIN_SEPARATOR;

    function __EIP712DomainVoting_init(string memory name, uint256 chainId) public initializer {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
           name: name,
           version: '1',
           chainId: chainId,
           verifyingContract: address(this)
       }));
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(Upvote memory upvote) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UPVOTE_TYPEHASH,
            upvote.voter,
            upvote.proposalId,
            upvote.timestamp,
            upvote.nonce
        ));
    }

    function verify(Upvote memory upvote, bytes memory signature) internal view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(upvote)
        ));

        address signer = _recoverSigner(digest, signature);

        return signer == upvote.voter;
    }

    function verify(address voter, uint256 proposalId, uint256 timestamp, uint256 nonce, bytes memory signature) internal view returns (bool) {
        
        Upvote memory upvote = Upvote({
            voter: voter,
            proposalId: proposalId,
            timestamp: timestamp,
            nonce: nonce
        });

        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(upvote)
        ));

        address signer = _recoverSigner(digest, signature);

        return signer == upvote.voter;
    }

    function _recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (_signature.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(_hash, v, r, s);
    }
}