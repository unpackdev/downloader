// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface WahICOEvents {
    event amountBought(
        uint8 _type,
        address buyerAddress,
        uint256 buyAmount,
        uint256 tokenAmount,
        uint256 tokenPrice,
        uint256 timestamp
    );

}
