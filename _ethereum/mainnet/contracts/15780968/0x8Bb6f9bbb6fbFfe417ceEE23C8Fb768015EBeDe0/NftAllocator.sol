//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Initializable.sol";
import "./Types.sol";
import "./console.sol";

contract SignatureStore is Ownable, Initializable {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct SignatureData {
        /// @notice location of the unhashed (full) data version
        string      termsUrl;
        /// @notice The wallet that signed the message
        address     signer;
        /// @notice Time that the message was signed
        uint256     numTokens;
        /// @notice Hashed version of the data
        bytes32     inviteCode;
        /// @notice number of tokens used to invest (founder: number of tokens to allocate)
        bytes32     termsHash;
    }
    
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        SignatureData data;
    }

    /// @notice ABI Encode Typehash for Signature Data
    bytes32 constant SIGNATURE_TYPEHASH = keccak256(
        "SignatureData(string termsUrl,address signer,uint256 numTokens,bytes32 inviteCode,bytes32 termsHash)"
    );

    /// @notice ABI Encode Typehash for EIP712 Domain
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /// @notice Hashed domain separator as per EIP721
    bytes32 public DOMAIN_SEPARATOR;

     /// @notice Hashed domain separator as per EIP721, used for foudner signature only, as we don't know contract address at initialization
    bytes32 public FOUNDER_DOMAIN_SEPARATOR;

    /// @notice Maps invite code to signature (for verification in NFT Allocator)
    mapping(address => Signature[]) public signatures;

    /// @notice owner signature, used on creation of allocator and signature store
    Signature public ownerSignature;

    /// @notice Data hash for Signature Data (used to verify signed hash matches expected)
    bytes32 public termsHash;

    /// @notice Data URL for Signature Data (used to verify signed hash matches expected)
    string public termsUrl;

    function initialize(Types.SignatureStoreNftAllocatorInitialConfig memory initialConfig, string memory name, address founder) external initializer {
        _transferOwnership(msg.sender);
        termsHash = initialConfig.termsHash;
        termsUrl = initialConfig.termsUrl; 

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: name,
            version: '1',
            chainId: block.chainid,
            verifyingContract: address(this)
        }));

        FOUNDER_DOMAIN_SEPARATOR = hash(EIP712Domain({
            name:name,
            version: '1',
            chainId: block.chainid,
            verifyingContract: founder
        }));

        Signature memory signature = _verifySignature(founder, initialConfig.config, FOUNDER_DOMAIN_SEPARATOR);
        ownerSignature = signature;
    }

    ///
    /// @notice Hash input data
    /// @param eip712Domain EIP712 Domain struct to be hashed
    ///
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
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
    function signatureHash(SignatureData memory s) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SIGNATURE_TYPEHASH,
            keccak256(bytes(s.termsUrl)),
            s.signer,
            s.numTokens,
            s.inviteCode,
            s.termsHash
        ));
    }

    ///
    /// @notice Save signed message (Typed EIP721 with Signature Data), after verifying the signer is the msg.sender
    /// @param config Signature config
    ///
    function saveSignature(Types.SignatureStoreNftAllocator memory config, address signer) public onlyOwner {
        Signature memory storedSignature = _verifySignature(signer, config, DOMAIN_SEPARATOR);
        signatures[signer].push(storedSignature);
    }

    function _verifySignature(address signer, Types.SignatureStoreNftAllocator memory config, bytes32 domain) private view returns(Signature memory) {
        SignatureData memory data = SignatureData({
            termsUrl:    termsUrl,
            signer:    signer,
            numTokens:  config.numTokens,
            inviteCode: config.inviteCode,
            termsHash:   termsHash
        });

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain,
            signatureHash(data)
        ));
          
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(config.signature);

        require(signer  == ecrecover(digest, v, r, s), "SignatureStore: Signer or data does not match");

        Signature memory storedSignature = Signature({
            data:  data,
            v: v,
            r: r,
            s: s
        });

        return storedSignature;
    }

    ///
    /// @notice Split a signature into (r s v) values, used for ecrecover
    /// @param signature The signed message
    ///
    function splitSignature(bytes memory signature)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }
}