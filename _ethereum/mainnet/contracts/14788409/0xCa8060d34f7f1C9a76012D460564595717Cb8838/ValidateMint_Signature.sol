// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";

import "./IBoredBoxNFT.sol";

import "./SignatureChecker.sol";

import "./BytesLib.sol";

import "./IValidateMint_Signature.sol";
import "./AValidateMint.sol";

/// Reusable validation contract for allowing pre-sale to owners of past Box generations
contract ValidateMint_Signature is AValidateMint, IValidateMint_Signature_Functions, Ownable {
    // Mapping boxId to ECDSA public key
    mapping(uint256 => address) public box__signer;

    /// @custom:throw "Invalid signer"
    /// @custom:throw "Invalid box ID"
    constructor(
        address owner_,
        uint256 boxId,
        address signer
    ) Ownable(owner_) {
        require(signer != address(0), "Invalid signer");
        require(boxId > 0, "Invalid box ID");
        box__signer[boxId] = signer;
    }

    /// @dev See {IValidateMint_Functions-validate}
    /// @custom:throw "Invalid signer"
    function validate(
        address, /* __to__ */
        uint256 boxId,
        uint256, /* __tokenId__ */
        bytes memory auth
    ) external view virtual override returns (uint256 validate_status) {
        require(box__signer[boxId] != address(0), "Invalid signer");

        bytes32 hash;
        assembly {
            hash := mload(add(auth, 32))
        }

        bytes memory signature = BytesLib.slice(auth, 32, auth.length - 32);

        require(SignatureChecker.isValidSignatureNow(box__signer[boxId], hash, signature), "Invalid signature");

        return VALIDATE_STATUS__PASS;
    }

    /// @dev See {IValidateMint_Signature_Functions-validate}
    function newBox(uint256 boxId, address signer) external onlyOwner {
        require(signer != address(0), "Invalid signer");
        require(boxId > 0, "Invalid box ID");
        require(box__signer[boxId] == address(0), "Signer already assigned");
        box__signer[boxId] = signer;
    }
}
