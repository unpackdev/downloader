// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract AxelNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("AxelNFT", "AXEL") {}

    function mintNFT(address recipient, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}