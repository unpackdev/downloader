//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";

contract Only100kRenderer is Ownable {
    string public revealedURI;

    constructor() {}

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));

    }

     function setBaseURI(string memory _baseUri) external payable onlyOwner {
        revealedURI = _baseUri;
    }
}