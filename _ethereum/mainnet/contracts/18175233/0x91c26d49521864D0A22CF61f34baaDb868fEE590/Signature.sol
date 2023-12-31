//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";

library Signature {
    using ECDSA for bytes32;
    function getSigner(address receiver, bytes memory _signature)
        internal
        view
        returns (address)
    {
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), msg.sender, receiver)
        );
        address signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );

        return signer;
    }

    function getAdvanceSigner(address receiver, uint amount, bytes memory _signature)
        internal
        view
        returns (address)
    {
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), msg.sender, receiver, Strings.toString(amount))
        );
        address signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );

        return signer;
    }
}