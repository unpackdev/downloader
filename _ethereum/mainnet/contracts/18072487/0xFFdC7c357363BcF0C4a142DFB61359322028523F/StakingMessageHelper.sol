// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {ECDSA} from "ECDSA.sol";
import {EIP712} from "EIP712.sol";

import {NftId} from "IChainNft.sol";


contract StakingMessageHelper is 
    EIP712
{
    string public constant EIP712_DOMAIN_NAME = "EtheriscStaking";
    string public constant EIP712_DOMAIN_VERSION = "1";

    // hint: user defined data typs don't work here, NftId -> uint96
    string public constant EIP712_STAKE_TYPE = "Stake(uint96 target,uint256 dipAmount,bytes32 signatureId)";
    bytes32 private constant EIP712_STAKE_TYPE_HASH = keccak256(abi.encodePacked(EIP712_STAKE_TYPE));

    string public constant EIP712_RESTAKE_TYPE = "Restake(uint96 stakeId,uint96 newTarget,bytes32 signatureId)";
    bytes32 private constant EIP712_RESTAKE_TYPE_HASH = keccak256(abi.encodePacked(EIP712_RESTAKE_TYPE));


    mapping(bytes32 signatureHash => bool isUsed) private _signatureIsUsed;


    constructor()
        EIP712(EIP712_DOMAIN_NAME, EIP712_DOMAIN_VERSION)
    // solhint-disable-next-line no-empty-blocks
    { }


    function processStakeSignature(
        address owner,
        NftId target,
        uint256 dipAmount,
        bytes32 signatureId, // ensures unique signatures even when all other attributes are equal
        bytes calldata signature
    )
        external 
    {
        bytes32 digest = getStakeDigest(target, dipAmount, signatureId);
        address signer = getSigner(digest, signature);

        _processSignature(owner, signer ,signature);
    }


    function processRestakeSignature(
        address owner,
        NftId stakeId,
        NftId newTarget,
        bytes32 signatureId, // ensures unique signatures even when all other attributes are equal
        bytes calldata signature
    )
        external 
    {
        bytes32 digest = getRestakeDigest(stakeId, newTarget, signatureId);
        address signer = getSigner(digest, signature);

        _processSignature(owner, signer ,signature);
    }


    function getStakeDigest(
        NftId target,
        uint256 dipAmount,
        bytes32 signatureId
    )
        public
        view
        returns(bytes32 digest)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                EIP712_STAKE_TYPE_HASH,
                target,
                dipAmount,
                signatureId));

        digest = _hashTypedDataV4(structHash);
    }


    function getRestakeDigest(
        NftId stakeId,
        NftId newTarget,
        bytes32 signatureId
    )
        public
        view
        returns(bytes32 digest)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                EIP712_RESTAKE_TYPE_HASH,
                stakeId,
                newTarget,
                signatureId));

        digest = _hashTypedDataV4(structHash);
    }


    function getSigner(
        bytes32 digest,
        bytes calldata signature
    )
        public
        pure
        returns(address signer)
    {
        return ECDSA.recover(digest, signature);
    }


    function _processSignature(
        address owner,
        address signer,
        bytes calldata signature
    )
        internal
    {
        bytes32 signatureHash = keccak256(abi.encode(signature));
        require(!_signatureIsUsed[signatureHash], "ERROR:SMH-001:SIGNATURE_USED");
        require(owner == signer, "ERROR:SMH-002:SIGNATURE_INVALID");
        _signatureIsUsed[signatureHash] = true;
    }    
}
