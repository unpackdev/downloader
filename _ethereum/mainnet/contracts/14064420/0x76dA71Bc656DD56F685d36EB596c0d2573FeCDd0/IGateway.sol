// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}
