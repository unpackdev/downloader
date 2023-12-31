// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "EIP712.sol";


contract DepegMessageHelper is 
    EIP712
{
    // EIP-712 Depeg specifics
    string public constant EIP712_DOMAIN_NAME = "EtheriscDepeg";
    string public constant EIP712_DOMAIN_VERSION = "1";

    string public constant EIP712_POLICY_TYPE = "Policy(address wallet,uint256 protectedBalance,uint256 duration,uint256 bundleId,bytes32 signatureId)";
    bytes32 private constant EIP712_POLICY_TYPE_HASH = keccak256(abi.encodePacked(EIP712_POLICY_TYPE));

    // tracking of signatures
    mapping(bytes32 /* signature hash */ => bool /* used */) private _signatureIsUsed;


    constructor()
        EIP712(EIP712_DOMAIN_NAME, EIP712_DOMAIN_VERSION)
    { }

    function checkAndRegisterSignature (
        address policyHolder,
        address protectedWallet,
        uint256 protectedBalance,
        uint256 duration,
        uint256 bundleId,
        bytes32 signatureId,
        bytes calldata signature
    )
        external 
    {
        bytes32 signatureHash = keccak256(abi.encode(signature));
        require(!_signatureIsUsed[signatureHash], "ERROR:DMH-001:SIGNATURE_USED");

        address signer = getSignerFromDigestAndSignature(
            protectedWallet,
            protectedBalance,
            duration,
            bundleId,
            signatureId,
            signature);

        require(policyHolder == signer, "ERROR:DMH-002:SIGNATURE_INVALID");

        _signatureIsUsed[signatureHash] = true;
    }

    function getSignerFromDigestAndSignature(
        address protectedWallet,
        uint256 protectedBalance,
        uint256 duration,
        uint256 bundleId,
        bytes32 signatureId,
        bytes calldata signature
    )
        public
        view
        returns(address)
    {
        bytes32 digest = getDigest(
                protectedWallet,
                protectedBalance,
                duration,
                bundleId,
                signatureId
            );

        return getSigner(digest, signature);
    }


    function getDigest(
        address protectedWallet,
        uint256 protectedBalance,
        uint256 duration,
        uint256 bundleId,
        bytes32 signatureId
    )
        internal
        view
        returns(bytes32)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                EIP712_POLICY_TYPE_HASH,
                protectedWallet,
                protectedBalance,
                duration,
                bundleId,
                signatureId
            )
        );

        return getTypedDataV4Hash(structHash);
    }
}
