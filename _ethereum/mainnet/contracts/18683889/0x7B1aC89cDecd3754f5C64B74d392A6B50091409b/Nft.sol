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
   
    constructor() ERC721("Mekane","MO") {
        owner=msg.sender;
        _safeMint(msg.sender, 0);
        _safeMint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public pure override(ERC721) returns(string memory){
        if(tokenId == 0)
            return "https://ipfs.io/ipfs/QmbhijuHrxiX6iScexaRNzGLNZ62bKFWe61tRs7vbGxnnw";
        else if (tokenId == 1)
            return "https://ipfs.io/ipfs/QmPYAVRXgAQUk17eEWUQvprnosZDMkzHMLtKv8WKPaBjNe";
    }

    function imageURI(uint256 tokenId) public pure virtual returns(string memory){
        return "https://ipfs.io/ipfs/QmRZpH7gSkAqSJtGP8mSWWEMq7ywA39gyUxNpDhYVW3HGP";
    }

    function contractURI() public pure returns(string memory){
        return "https://ipfs.io/ipfs/QmPxPsVaz8TzSEwsYGRzgyDTeHTytv8rGPu8R6sjBsxqCj";
    }


   
}