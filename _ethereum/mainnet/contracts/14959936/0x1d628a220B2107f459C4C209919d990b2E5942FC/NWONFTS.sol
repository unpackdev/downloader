//contracts/NWONFTS.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./ERC721URIStorage.sol"; // changed import
import "./Counters.sol";
import "./Ownable.sol";


contract NWONFTS is ERC721URIStorage, Ownable { // changed parent
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("NWOC", "NWO") {}

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