// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.21;
pragma abicoder v2;

import "./IERC721.sol";

contract SignatureVerifier {
    struct Permit {
        address spender;
        uint256 deadline;
    }

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable PERMIT_TYPEHASH;

    error InvalidSignature();

    constructor(string memory _name) {
        DOMAIN_SEPARATOR = _computeDomainSeparator(bytes(_name));
        PERMIT_TYPEHASH = keccak256("Permit(address spender,uint256 deadline)");
    }

    function _verifySignature(address sender, uint256 deadline, uint8 v, bytes32 r, bytes32 s, address verifier)
        internal
        view
    {
        bytes32 typedDataHash = getTypedDataHash(Permit(sender, deadline));
        address recoveredAddress = ecrecover(_prefixed(typedDataHash), v, r, s);

        if (recoveredAddress == address(0) || recoveredAddress != verifier) revert InvalidSignature();
    }

    /// @dev computes the hash of the fully encoded EIP-712 message for the domain,
    /// which can be used to recover the signer
    /// @param _permit The permit struct
    /// @return bytes32 The hash of the fully encoded EIP-712 message for the domain
    function getTypedDataHash(Permit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _getStructHash(_permit)));
    }

    /// @dev returns the domain separator for the contract
    /// @param _name The name of the contract
    /// @return bytes32 The domain separator for the contract
    function _computeDomainSeparator(bytes memory _name) internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(_name),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev computes the hash of a permit struct
    /// @param _permit The permit struct
    /// @return bytes32 The hash of the permit struct
    function _getStructHash(Permit memory _permit) internal view returns (bytes32) {
        return keccak256(abi.encode(PERMIT_TYPEHASH, _permit.spender, _permit.deadline));
    }

    /// @dev Builds a prefixed hash to mimic the behavior of eth_sign.
    /// @param hash The hash to prefix
    /// @return bytes32 The prefixed hash
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
