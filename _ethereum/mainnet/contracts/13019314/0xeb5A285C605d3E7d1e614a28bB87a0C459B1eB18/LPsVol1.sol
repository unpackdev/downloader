// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract LPsVol1 is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;

    constructor() ERC721("LPs Vol. 1", "LPV1") {}

    function press(string memory _tokenURI) public onlyOwner returns (uint256) {
        _counter.increment();
        uint256 newId = _counter.current();

        _safeMint(msg.sender, newId);
        _setTokenURI(newId, _tokenURI);

        return newId;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function countLPs() public view returns (uint256) {
        return _counter.current();
    }
}
