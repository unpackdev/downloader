//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";

contract PeriodicalsCollection is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 25;
    uint256 public constant PRICE = 0.1 ether;


    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("SuperStonk Periodicals Collection", "GMEP") {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mintNFTs(uint256 _count) public payable {
        uint256 totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "0 left");
       
        require(
            msg.value >= PRICE.mul(_count),
            "Need more $"
        );

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No $ left");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "T failed.");
    }
}
