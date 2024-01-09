// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

// 3.1.0-solc-0.7 openzeppelin
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract ERC721NFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory tokenName, string memory tokenSymbol) public ERC721(tokenName, tokenSymbol) {}

    function mint(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

}