// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // solhint-disable-line compiler-version

import "./ECDSA.sol";

import "./StorageSlotOwnable.sol";

import "./AirdropRegistryStorage.sol";

abstract contract AirdropRegistryVerify is AirdropRegistryStorage, StorageSlotOwnable {
    function hashAirdropInfo(AirdropInfo memory d) private view returns (bytes32) {
        require(d.chainID == block.chainid, "chain id mismatch");
        return keccak256(abi.encode(d.token, d.beneficiary, d.amount, d.nonce, d.chainID));
    }

    function verifyAirdropInfo(AirdropInfo memory d, bytes memory signature)
        public
        view
        returns (bool success, bytes32 hash)
    {
        hash = hashAirdropInfo(d);
        success = ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) == owner();
    }
}
