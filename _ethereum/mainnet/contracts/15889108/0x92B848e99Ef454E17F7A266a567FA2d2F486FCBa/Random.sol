// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Random {
    function random(
        uint256 _from,
        uint256 _to,
        uint256 _nonce
    ) internal view returns (uint256) {
        uint256 randNonce = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _nonce)));
        return (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randNonce))) % _to) + _from;
    }

    function random8(
        uint256 _from,
        uint256 _to,
        uint256 _nonce
    ) internal view returns (uint8) {
        return uint8(random(_from, _to, _nonce));
    }
}
