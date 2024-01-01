// SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

library SignatureUtil {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct SignatureData {
        /// @notice The wallet that signed the message
        address signer;
        /// @notice location of the unhashed (full) data version
        string termsUrl;
        /// @notice hashed version of the terms url content
        bytes32 termsHash;
        /// @notice number of tokens to purchase (founder: number of tokens to allocate)
        uint256 numTokens;
        /// @notice Price (number of treasury type tokens e.g. $USDC) per sale token
        uint256 tokenPrice;
        /// @notice minimum tokens to be purchased for the sale to be successful
        uint256 hurdle;
        /// @notice the date at which the token is expected to be minted and the token release scheduled starts
        uint256 releaseScheduleStartTimeStamp;
        /// @notice period that tokens are locked before they start being released
        uint256 tokenLockDuration;
        /// @notice period over which tokens are released for claiming after `tokenLockDuration`
        uint256 releaseDuration;
        /// @notice invite code used for the purchase, or the merkletree root for all invite codes when creating the sale
        bytes32 inviteCode;
    }

    /// @notice ABI Encode Typehash for Signature Data
    bytes32 constant SIGNATURE_TYPEHASH = keccak256(
        "SignatureData(address signer,string termsUrl,bytes32 termsHash,uint256 numTokens,uint256 tokenPrice,uint256 hurdle,uint256 releaseScheduleStartTimeStamp,uint256 tokenLockDuration,uint256 releaseDuration,bytes32 inviteCode)"
    );

    /// @notice ABI Encode Typehash for EIP712 Domain
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    ///
    /// @notice Hash input data
    /// @param eip712Domain EIP712 Domain struct to be hashed
    ///
    function hashDomain(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    ///
    /// @notice Hash input data
    /// @param s Signature Data struct to be hashed
    ///
    function signatureDataHash(SignatureData memory s) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SIGNATURE_TYPEHASH,
            s.signer,
            keccak256(bytes(s.termsUrl)),
            s.termsHash,
            s.numTokens,
            s.tokenPrice,
            s.hurdle,
            s.releaseScheduleStartTimeStamp,
            s.tokenLockDuration,
            s.releaseDuration,
            s.inviteCode
        ));
    }

    function verifySignature(bytes32 domain, SignatureData memory data, bytes memory signature) internal pure returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain,
            signatureDataHash(data)
        ));

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(signature);
        return data.signer == ecrecover(digest, v, r, s);
    }

    ///
    /// @notice Split a signature into (r s v) values, used for ecrecover
    /// @param signature The signed message
    ///
    function splitSignature(bytes memory signature) internal pure returns (uint8, bytes32, bytes32) {
        require(signature.length == 65, "SignatureVerification: Invalid Signature");
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }
}
