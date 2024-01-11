// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./IUgokiCOA.sol";

contract UgokiCOA is ERC721URIStorage, Ownable, IUgokiCOA {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor() ERC721("Ugoki Watches Certificate of Authenticity", "UCOA") {}

    function mint(address _owner, string memory _tokenURI) override external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(_owner, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        return newItemId;
    }

    function mintedCount() public view returns (uint256) {
        return _tokenIds.current();
    }
}
