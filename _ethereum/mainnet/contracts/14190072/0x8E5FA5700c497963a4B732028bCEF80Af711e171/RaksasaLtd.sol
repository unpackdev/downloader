// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract RaksasaLtd is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Raksasa Ltd.", "RKLTD") {}

    function createLimitedEdition(
        address[] calldata addressList,
        string[] memory tokenUriList
    ) external onlyOwner {
        require(tokenUriList.length == addressList.length, "Wrong Inputs");
        for (uint256 i = 0; i < addressList.length; ++i) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenUriList[i]);
        }
    }

    function currentId() public view returns (uint256) {
        return _tokenIds.current();
    }
}
