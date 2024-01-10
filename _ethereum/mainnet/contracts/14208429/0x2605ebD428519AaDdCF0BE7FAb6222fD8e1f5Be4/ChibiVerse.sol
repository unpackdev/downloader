// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ChibiVerse is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    string private baseURI;

    // CONSTANT
    string public constant PROVENANCE =
        "d1989a129dfa326cff26253b71cb0b50763868c8329b59b8915bfdbdd0562b3c";
    uint256 public constant MAX_CHIBI_PURCHASE = 20;
    uint256 public constant MAX_CHIBI = 10000;
    uint256 public constant CHIBI_PRICE = 0.006 ether;

    constructor(string memory uri) ERC721("ChibiVerse", "CHIBI") {
        baseURI = uri;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount) public payable {
        require(
            _mintAmount > 0 && _mintAmount <= MAX_CHIBI_PURCHASE,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount <= MAX_CHIBI,
            "Max supply exceeded!"
        );
        require(msg.value >= CHIBI_PRICE * _mintAmount, "Insufficient funds!");

        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory _newBaseUri) public onlyOwner {
        baseURI = _newBaseUri;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
