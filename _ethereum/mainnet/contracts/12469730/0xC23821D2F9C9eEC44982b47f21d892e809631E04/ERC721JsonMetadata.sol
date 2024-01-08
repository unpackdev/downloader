// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";

abstract contract ERC721JsonMetadata is ERC721Burnable {
    using Strings for uint256;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721JsonMetadata: URI query for nonexistent token");
        return concat(baseURI(), tokenId.toString(), ".json");
    }

    function contractURI() public view returns (string memory) {
        return concat(baseURI(), "contract.json");
    }

    function concat(string memory a, string memory b) private pure returns(string memory){
        return string(abi.encodePacked(a,b));
    }

    function concat(string memory a, string memory b, string memory c) private pure returns(string memory){
        return string(abi.encodePacked(a,b,c));
    }

}
