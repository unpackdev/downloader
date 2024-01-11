// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./console.sol";

import "./Base64.sol";

contract AvatarNFT is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721 ("nfts by de", "EJRN") {}

    function mintNFT(string memory url) public onlyOwner {
        uint256 id = _tokenIds.current();
        _safeMint(msg.sender, id);
        _setTokenURI(id, url);
        _tokenIds.increment();
    }
}