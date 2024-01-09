// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

abstract contract BaseURI is ERC721, Ownable {
    string private baseURI = "";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }
}