// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract MemoryBankNFT is ERC1155, Ownable {

    mapping(uint256 => string) private _tokenMetadata;

    constructor() ERC1155("") { }
    
    function mintNFT(uint256 concertId, uint256 quantity, string memory tokenURI)
        public onlyOwner {
        _mint(msg.sender, concertId, quantity, "");
        _tokenMetadata[concertId] = tokenURI;
    }
    
    function uri(uint256 _tokenId) override 
        public view
        returns (string memory) {
        return string(abi.encodePacked(_tokenMetadata[_tokenId]));
    }
}
