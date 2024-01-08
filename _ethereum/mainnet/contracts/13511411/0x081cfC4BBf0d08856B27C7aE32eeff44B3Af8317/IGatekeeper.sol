// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IGatekeeper {
    function allowed(
        address signer,
        uint256 glitch
    ) external view returns (bool);
}