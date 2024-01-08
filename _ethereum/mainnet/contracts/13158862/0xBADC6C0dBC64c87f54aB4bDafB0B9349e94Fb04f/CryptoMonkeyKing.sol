// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract MonkeyKingClub is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public MAX_SUPPLY = 8888;

    constructor() ERC721("MonkeyKingClub", "MKC") {}

    function mint(address receiver, string memory tokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        require(newNftTokenId <= MAX_SUPPLY, "Exceed max members of MonkeyKingClub");
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }
}