// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Ownable from the OpenZeppelin Contracts library
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
//import "./Ownable.sol";
// Make Box inherit from the Ownable contract
contract Nft is ERC721Enumerable {
    address public owner;
   
    constructor() ERC721("Mekane","BO") {
        owner=msg.sender;
        _safeMint(msg.sender, 0);
        _safeMint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public pure override(ERC721) returns(string memory){
        if(tokenId == 0)
            return "https://ipfs.io/ipfs/QmRnNajzP3Jqqa5qRSngHXrZGqPJmB8ECzw6srQCKSJNP4";
        else if (tokenId == 1)
            return "https://ipfs.io/ipfs/QmPWouLdTtFJ88TsJREevkD3pTYnVww4D2aAgpK3ghtRro";
    }

    function imageURI(uint256 tokenId) public pure virtual returns(string memory){
        return "https://ipfs.io/ipfs/QmVpnrarCqgQ63HKHa4hBgUdoYBUq2EWaBG9BkH4egP9oN";
    }

    function contractURI() public pure returns(string memory){
        return "https://ipfs.io/ipfs/QmYMht4sTM56xQ7spNiwQRAiDwg79CKviQFvECsZTuivt9";
    }


   
}