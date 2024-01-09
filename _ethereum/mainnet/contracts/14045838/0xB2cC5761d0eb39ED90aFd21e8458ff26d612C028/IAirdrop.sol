// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAirdrop {
    function claimAirdrop(uint16[] calldata) external;
    function donate(uint16[] calldata) external;
    function isTokenUsed(uint16) external view returns (bool);
    
    event Received(address, uint);
    event AirdropClaim(address, uint);
    event Donate(address, uint);
}