// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract PoW {
    mapping(uint256 => bool) private _usedNonce;

    uint256 public DIFFICULTY;

    function _verifyPoW(uint256 nonce) internal {
        require(!_usedNonce[nonce], "Nonce already used");
        _usedNonce[nonce] = true;

        bytes32 hash = keccak256(
            abi.encodePacked(address(this), msg.sender, nonce, DIFFICULTY)
        );

        uint256 target = ~uint256(0) / DIFFICULTY; // ~uint256(0) equals 2^256 - 1
        require(uint256(hash) < target, "PoW verification failed");
    }
}
