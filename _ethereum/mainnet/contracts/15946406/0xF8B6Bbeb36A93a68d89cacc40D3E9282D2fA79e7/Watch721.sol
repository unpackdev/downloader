// SPDX-License-Identifier: MIT
/*
https://watchchain.com/
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Watch721 is Ownable, ERC721("WatchChain", "Watch721") {
    string private _baseURIstring = "";

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseURIstring;
    }

    function mint(address to, uint256 tokenIds) external onlyOwner {
        _mint(to, tokenIds);
    }

    function setBaseURI(string memory baseURIstring) external onlyOwner {
        _baseURIstring = baseURIstring;
    }

    function exists(uint256 tokenId) public view returns(bool){
        return _exists(tokenId);
    }
}
