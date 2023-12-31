// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract yjNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;

    constructor() ERC721("yjNFT", "yjNFT") {}

    function mintNFT(address recipient, string memory tokenURI)
        public onlyOwner
    {
		uint256 itemId = _tokenIds;
        _mint(recipient, itemId);
        _setTokenURI(itemId, tokenURI);
		_tokenIds += 1;
    }
}