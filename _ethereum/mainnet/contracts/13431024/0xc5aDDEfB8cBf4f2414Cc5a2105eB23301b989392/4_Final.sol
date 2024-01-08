// contracts/NftDresses.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract LibresseDigitalDress is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint8 constant _maxCount = 20;

    constructor() ERC721("Libresse Digital Dress", "LDR") {}

    function mintNft(address receiver, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 nftTokenId = _tokenIds.current();
        require(nftTokenId < _maxCount, "Counter: maximum number of nft items");

        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }
}