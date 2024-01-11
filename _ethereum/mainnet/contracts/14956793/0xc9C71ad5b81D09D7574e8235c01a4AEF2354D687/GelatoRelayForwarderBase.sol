// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./RequestTypes.sol";
import "./ECDSA.sol";

abstract contract GelatoRelayForwarderBase {
    bytes32 public constant FORWARD_REQUEST_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "ForwardRequest(uint256 chainId,address target,bytes data,address feeToken,uint256 paymentType,uint256 maxFee,uint256 gas,address sponsor,uint256 sponsorChainId,uint256 nonce,bool enforceSponsorNonce,bool enforceSponsorNonceOrdering)"
            )
        );
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    function _getDomainSeparator(uint256 _chainId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(bytes(EIP712_DOMAIN_TYPE)),
                    keccak256(bytes("GelatoRelayForwarder")),
                    keccak256(bytes("V1")),
                    bytes32(_chainId),
                    address(this)
                )
            );
    }

    function _verifyForwardRequestSignature(
        ForwardRequest calldata _req,
        bytes calldata _signature,
        address _expectedSigner
    ) internal view returns (bytes32) {
        bytes32 domainSeparator = _getDomainSeparator(_req.chainId);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(_abiEncodeForwardRequest(_req))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "Invalid signature"
        );

        return digest;
    }

    function _abiEncodeForwardRequest(ForwardRequest calldata _req)
        internal
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            FORWARD_REQUEST_TYPEHASH,
            _req.chainId,
            _req.target,
            keccak256(_req.data),
            _req.feeToken,
            _req.paymentType,
            _req.maxFee,
            _req.gas,
            _req.sponsor,
            _req.sponsorChainId,
            _req.nonce,
            _req.enforceSponsorNonce,
            _req.enforceSponsorNonceOrdering
        );
    }
}
