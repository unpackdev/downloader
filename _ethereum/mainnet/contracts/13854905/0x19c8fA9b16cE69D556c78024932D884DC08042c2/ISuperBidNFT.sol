// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface ISuperBidNFT {
    function mint(uint256 _id, address _owner, string memory url) external;
}