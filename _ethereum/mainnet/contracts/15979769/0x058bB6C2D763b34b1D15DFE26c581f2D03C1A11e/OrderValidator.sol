// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1271.sol";
import "./LibOrder.sol";
import "./LibSignature.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";

abstract contract OrderValidator is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable
{
    using LibSignature for bytes32;
    using AddressUpgradeable for address;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    function __OrderValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Shiniki", "1");
    }

    function _verifySignature(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        if (order.salt != 0) {
             if (_msgSender() != order.maker) {
                bytes32 hash = LibOrder.hash(order);
                address signer = address(0);
                if (signature.length == 65) {
                    signer = _hashTypedDataV4(hash).recover(signature);
                }
                if (signer != order.maker) {
                    if (order.maker.isContract()) {
                        require(
                            IERC1271(order.maker).isValidSignature(
                                _hashTypedDataV4(hash),
                                signature
                            ) == MAGICVALUE,
                            "contract order signature verification error"
                        );
                    } else {
                        revert("order signature verification error");
                    }
                }
            }
        } else {
            if (order.maker != address(0)) {
                require(_msgSender() == order.maker, "maker is not tx sender");
            } else {
                order.maker = _msgSender();
            }
        }
    }
}
