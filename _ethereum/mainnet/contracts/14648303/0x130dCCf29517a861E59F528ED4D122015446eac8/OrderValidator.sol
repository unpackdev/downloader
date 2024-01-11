//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./draft-EIP712.sol";
import "./Context.sol";
import "./LibOrder.sol";

abstract contract OrderValidator is Context, EIP712 {
    function validate(LibOrder.Order calldata order) internal view {
        require(order.maker != address(0), "no maker");

        if (_msgSender() == order.maker) {
            return;
        }

        bytes32 hash = LibOrder.hash(order);
        address signer;
        if (order.signature.length == 65) {
            bytes32 digest = _hashTypedDataV4(hash);
            signer = ECDSA.recover(digest, order.signature);
        }

        require(signer == order.maker, "order signature verification error");
    }

    // todo::remove for prod
    // function recoverOrderSigner(LibOrder.Order calldata order)
    //     public
    //     view
    //     returns (address)
    // {
    //     bytes32 digest = _hashTypedDataV4(LibOrder.hash(order));

    //     return ECDSA.recover(digest, order.signature);
    // }
}
