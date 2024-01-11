// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract FunkyPizza is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenSupply;

    bool public paused = false;

    uint256 public constant max_supply = 2205;
    uint256 public maxPerMint = 10;
    uint256 public price = 0;

    string public baseURI;

    constructor(string memory _initBaseURI) ERC721("FunkyPizza", "FUNKY") {
        setBaseURI(_initBaseURI);
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "Mint is paused");
        require(_mintAmount > 0, "Must mint at least one FunkyPizza");
        require(
            _mintAmount <= maxPerMint,
            "Mint amount must be less than or equal to max mint amount"
        );
        require(
            msg.value >= price * _mintAmount,
            "Not enough ETH supplied for transaction"
        );

        require(
            _tokenSupply.current() + _mintAmount <= max_supply,
            "Not enough supply for minting"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //  ADMIN AREA  //

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxPerMint(uint256 _newMaxPerMint) public onlyOwner {
        maxPerMint = _newMaxPerMint;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function reserve(uint256 _mintAmount) public onlyOwner {
        require(_mintAmount > 0, "Must mint at least one FunkyPizza");
        require(
            _tokenSupply.current() + _mintAmount <= max_supply,
            "Not enough supply for reserving"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Failed to send ether to the owner");
    }
}
