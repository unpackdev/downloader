// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface NFTMintable {
    function mintTo(address to, uint16 amount) external;
}
