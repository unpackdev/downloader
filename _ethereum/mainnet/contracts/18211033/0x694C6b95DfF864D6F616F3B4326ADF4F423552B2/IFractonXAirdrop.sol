// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFractonXAirdrop {
    event Claim(
        address indexed user,
        uint256 indexed signatureId,
        address indexed tokenAddr,
        uint256 amount
    );

    event SetValidSigner(address signer, bool isValid);
}
