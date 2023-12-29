// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

// 
// All-access pass purr-mit to UniswapVillain's lair.
// 
// Former FT Key Holders missing their NFT please DM @UniswapVillain on TG or Twitter or Signal. 
// NFTs have and can be minted for those that did not convert in a timely manner.
// 
// https://twitter.com/UniswapVillain
// 
contract PurrPass is ERC721A, Ownable {

    string private _baseTokenURI;

    constructor() ERC721A("Purr Pass", "PURR") {}

    function mint(address _address) external onlyOwner {
        _mint(_address, 1);
    }

    function mint(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }    
}