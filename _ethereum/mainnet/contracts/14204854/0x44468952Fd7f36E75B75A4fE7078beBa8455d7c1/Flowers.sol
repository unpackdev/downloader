//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Flowers is ERC721URIStorage, ERC721Burnable, Ownable {
    string  public baseURI;
    uint256 public _supply = 144;

    using Counters for Counters.Counter;
    Counters.Counter public _counter;

    constructor(string memory uri) ERC721 ("[ MFFVD ]", "FLWR") {
        setBaseURI(uri);
        _counter.increment();
    }

    function mint(address[] calldata dest) public onlyOwner {
        require(((_counter.current() - 1) + dest.length) <= _supply, "Request exceeds supply cap");

        for(uint256 i = 0; i < dest.length; i++) {
            _safeMint(dest[i], _counter.current());
            _setTokenURI(_counter.current(), Strings.toString(_counter.current()));
            _counter.increment();
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }


}
