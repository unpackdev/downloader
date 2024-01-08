// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ClaimAllFix is Ownable {

    constructor() Ownable() {}

    mapping (address => uint256[]) tokenIdsByAddress;

    function tokensOfOwner(address owner, uint256 totalSupply) external view returns (uint256[] memory ownerTokens) {
        return tokenIdsByAddress[owner];
    }

    function addTokensToOwner(address owner, uint256[] memory tokensIds) public onlyOwner {
        tokenIdsByAddress[owner] = tokensIds;
    }
    
}