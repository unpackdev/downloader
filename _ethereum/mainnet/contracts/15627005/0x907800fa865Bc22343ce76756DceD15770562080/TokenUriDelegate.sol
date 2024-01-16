// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";

import "./ITokenUriDelegate.sol";

contract TokenUriDelegate is ITokenUriDelegate, Ownable {
    string baseURI_;

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseURI_ = baseURI;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(baseURI_, Strings.toString(tokenId)));
    }
}
