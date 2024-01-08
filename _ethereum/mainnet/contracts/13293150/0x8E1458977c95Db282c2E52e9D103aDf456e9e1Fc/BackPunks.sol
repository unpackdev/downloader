// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BackPunks is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 100;
    uint256 private _price = 0.01 ether;
    bool public _paused = true;

    // withdraw addresses
    address t1 = 0xa586c2Bb8600dc23d451e03a5A83eC79F082B7Fc;
    address t2 = 0xbBD772485b4Ef19e4eFAf21379475958b3c28C9f;
    address t3 = 0xBb71f1bF75b205bC908aBbf5BCb16DE65C078299;
    address t4 = 0x8c9d203bA9CF5485A408193F5296C7f044149A17;

    modifier onlyManager() {
        require(
            msg.sender == t1 ||
                msg.sender == t2 ||
                msg.sender == t3 ||
                msg.sender == t4 ||
                msg.sender == owner(),
            "Only manager can call this function."
        );
        _;
    }

    constructor(string memory baseURI) ERC721("BackPunks", "BPNKS") {
        setBaseURI(baseURI);
    }

    function mintBackPunks(uint256 num_) public payable {
        uint256 supply = totalSupply();
        require(!_paused, "Sale paused");
        require(num_ < 21, "You can mint a maximum of 20 BackPunks at a time");
        require(
            supply + num_ < 7778 - _reserved,
            "Exceeds maximum BackPunks supply"
        );
        require(msg.value >= _price * num_, "Ether sent is not correct");

        for (uint256 i; i < num_; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function backPunksOfOwner(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner_);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokensId;
    }

    function ownerOfBackPunk(uint256 backPunkId_)
        public
        view
        returns (address)
    {
        return ownerOf(backPunkId_);
    }

    function setPrice(uint256 newPrice_) public onlyOwner {
        _price = newPrice_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function giveAway(address to_, uint256 amount_) external onlyOwner {
        require(amount_ <= _reserved, "Exceeds reserved BackPunks supply");

        uint256 supply = totalSupply();
        for (uint256 i; i < amount_; i++) {
            _safeMint(to_, supply + i);
        }

        _reserved -= amount_;
    }

    function pause(bool val_) public onlyOwner {
        _paused = val_;
    }

    function isMinted(uint256 backPunkId_) public view returns (bool) {
        return _exists(backPunkId_);
    }

    function withdrawAll() public payable onlyManager {
        uint256 _each = address(this).balance / 4;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
        require(payable(t3).send(_each));
        require(payable(t4).send(_each));
    }
}
