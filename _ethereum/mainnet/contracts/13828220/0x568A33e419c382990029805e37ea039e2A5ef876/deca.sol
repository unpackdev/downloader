//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract Deca is ERC721URIStorage, Ownable {

    constructor() public ERC721("0xA", "0xA") {}

    function mintNFT(address recipient, string memory tokenURI, uint256 tokenId)
        public onlyOwner
        returns (uint256)
    {

        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }
}
