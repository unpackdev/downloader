// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract BlueChimp is ERC721URIStorage, Ownable {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 limit = 1000;
    bool allow_minting = true;

    constructor() ERC721("BlueChimp", "BCNFT") {}

    function mintNFT(address recipient, string memory tokenURI) public onlyOwner returns (uint256)
    {
        uint256 newItemId = 0;

        if(_tokenIds.current() < limit)
        {
            _tokenIds.increment();

            newItemId = _tokenIds.current();

            _mint(recipient, newItemId);

            _setTokenURI(newItemId, tokenURI);
        }

        return newItemId;
    }

    function changeLimit(uint256 _limit) public {
        limit = _limit;
    }

    function changeAllowance(bool _allow) public {
        allow_minting = _allow;
    }
}