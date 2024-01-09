//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

contract MiniLarvaChads is Ownable, PaymentSplitter, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _apiURI = "";
    uint256 public _maxSupply = 5000;
    uint256 public _maxAmountToMint = 25;
    bool public _isMintingAllowed = false;
    uint256 public _itemPrice = 0.001 ether;

    uint256[] private _shares = [60, 40];
    address[] private _shareholders = [
        0x918fb08A4E6b15374e558Ef053b2d404DDaC6a2D,
        0x6F8d91A68FdE89Aa933203B038A064608eeE4430
    ];

    modifier mintingAllowed() {
        require(_isMintingAllowed, "Minting not allowed");
        _;
    }

    modifier enoughFunds(uint256 _amountToMint) {
        require(
            msg.value >= _itemPrice.mul(_amountToMint),
            "Insufficient funds"
        );
        _;
    }

    modifier limitTokensToMint(uint256 _amountToMint) {
        require(_amountToMint <= _maxAmountToMint, "Too many tokens at once");
        _;
    }

    modifier limitSupply(uint256 _amountToMint) {
        require(
            _maxSupply >= _tokenIds.current().add(_amountToMint),
            "The purchase would exceed max tokens supply"
        );
        _;
    }

    constructor()
        PaymentSplitter(_shareholders, _shares)
        ERC721("Mini Larva Chads", "MLChads")
    {}

    function mintMultiple(uint256 _amountToMint)
        public
        payable
        mintingAllowed
        limitSupply(_amountToMint)
        enoughFunds(_amountToMint)
        limitTokensToMint(_amountToMint)
    {
        for (uint256 i = 0; i < _amountToMint; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    function mintGiveaway(uint256 _amountToMint)
        public
        onlyOwner
        limitSupply(_amountToMint)
    {
        for (uint256 i = 0; i < _amountToMint; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _apiURI = _uri;
    }

    function toggleMintingStatus() public onlyOwner {
        _isMintingAllowed = !_isMintingAllowed;
    }

    function setMaxAmountToMint(uint256 maxAmountToMint) public onlyOwner {
        _maxAmountToMint = maxAmountToMint;
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        _itemPrice = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        _maxSupply = _supply;
    }

    function withdrawParitial() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function releaseAll() public onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }
}
