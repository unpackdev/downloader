// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./TraderManager.sol";
import "./IERC1271.sol";

/**
 * @title SignatureValidator
 * @notice Implementation of ERC1271.
 */
abstract contract SignatureValidator is IERC1271, TraderManager {

    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) external view override returns (bytes4) {
        address signer = recoverSigner(_hash, _signature);
        // Validate signatures
        if (isTrader(signer)) {
            return IERC1271.isValidSignature.selector;
        } else {
            return 0xffffffff;
        }
    }

    /**
     * @notice Recover the signer of hash, assuming it's an EOA account
     * @dev Only for EthSign signatures
     * @param _hash       Hash of message that was signed
     * @param _signature  Signature encoded as (bytes32 r, bytes32 s, uint8 v)
     */
    function recoverSigner(
        bytes32 _hash,
        bytes memory _signature
    ) internal pure returns (address signer) {
        require(_signature.length == 65, "invalid signature length");

        // Variables are not scoped in Solidity.
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := and(mload(add(_signature, 0x41)), 0xff)
        }

        // Recover ECDSA signer
        signer = ecrecover(_hash, v, r, s);

        // // Prevent signer from being 0x0
        // require(
        //     signer != address(0x0),
        //     "INVALID_SIGNER"
        // );

        return signer;
    }
}
