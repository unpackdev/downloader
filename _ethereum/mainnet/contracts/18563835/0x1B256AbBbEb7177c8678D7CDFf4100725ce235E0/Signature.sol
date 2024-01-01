//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ECDSA.sol";
import "./Strings.sol";

library Signature {
    using ECDSA for bytes32;
    function getSigner(address receiver, bytes memory _signature)
        internal
        view
        returns (address signer)
    {
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), msg.sender, receiver)
        );
        signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );
    }

    function getAdvanceSigner(address receiver, uint amount, bytes memory _signature)
        internal
        view
        returns (address signer)
    {
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), msg.sender, receiver, Strings.toString(amount))
        );
        signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );
    }
}