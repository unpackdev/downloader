// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

//import "./LibERC721LazyMint.sol";
import "./EIP712Upgradeable.sol";
import "./LibSignature.sol";

abstract contract ERC1271ValidatorForERC721 is EIP712Upgradeable {
    using AddressUpgradeable for address;
    using LibSignature for bytes32;

    string constant SIGNATURE_ERROR = "signature verification error";
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    function validate1271(address signer, bytes32 structHash, bytes memory signature) internal view {
        bytes32 hash = _hashTypedDataV4(structHash);

        address signerFromSig;
        if (signature.length == 65) {
            signerFromSig = hash.recover(signature);
        }
        require(signerFromSig == signer, "ERC721: signature verification error");
    }
    uint256[50] private __gap;
}

contract Mint721Validator is ERC1271ValidatorForERC721 {
    function __Mint721Validator_init_unchained() internal initializer {
        __EIP712_init_unchained("Mint721", "1");
    }

    function validate(address account, bytes32 hash, bytes memory signature) internal view {
        validate1271(account, hash, signature);
    }
    uint256[50] private __gap;
}
