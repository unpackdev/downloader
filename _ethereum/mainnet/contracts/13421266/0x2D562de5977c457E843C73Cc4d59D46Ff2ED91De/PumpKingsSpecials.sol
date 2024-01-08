// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract PumpKingsSpecials is ERC721, Ownable {

    string public baseURI;
    uint public totalSupply;

    constructor() ERC721("PUMP KINGS Specials", "PMPKNGSP") {
        baseURI = "https://storage.googleapis.com/pumpkings/specials/meta/";
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            mintNFTs(addresses[i], amounts[i]);
        }
    }

    function mintNFTs(address account, uint amount) internal {
        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(account, fromToken + i);
        }
    }

}