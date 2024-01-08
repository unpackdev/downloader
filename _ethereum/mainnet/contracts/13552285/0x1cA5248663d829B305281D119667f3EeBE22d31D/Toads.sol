// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

interface IExternalWhiteList {
    function isWhitelisted(address _address) external view returns (bool);
}

contract Toads is Ownable, PaymentSplitter, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) internalWhitelist;

    string private _apiURI = "";
    uint256 public _maxSupply = 9000;
    uint256 public _maxAmountToMint = 2;
    uint256 public _maxAmountToHold = 2;
    bool public _isMintingAllowed = false;
    uint256 public _itemPrice = 0.07 ether;
    address public externalWhitelistAddress;
    bool public _isMintingAllowedWhitelist = false;

    uint256[] private _shares = [16,16,16,16,16,16];
    address[] private _shareholders = [
        0x20983da4656448e21EB0bcF5B72f100D2921c4a0,
        0x4658dC497FcAbFAb8Ae5DBB7A0f79417a9bbb8Bb,
        0xbb6F329f2C1917f7185dE1fBC5B88d490C1bFA80,
        0xC25A517a75dC587B3ae63258044bb3C70801DB52,
        0x3783804D0db6B4ea5AC20614c31EE8C96D8C1461,
        0xcAfF2f90a908e1165C17DBc33cE629465eb41Cf1
    ];

    modifier mintingAllowed() {
        require(
            _isMintingAllowed ||
                (_isMintingAllowedWhitelist && isWhitelisted(msg.sender)),
            "Minting not allowed"
        );
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Must use EOA");
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

    modifier limitTokensToHold(uint256 _amountToMint) {
        if (!_isMintingAllowed) {
            require(
                balanceOf(msg.sender).add(_amountToMint) <= _maxAmountToHold,
                "Tokens limit reached"
            );
        }
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
        ERC721("Pastel Toads", "PATO")
    {}

    function _mintMultiple(uint256 _amountToMint) private {
        for (uint256 i = 0; i < _amountToMint; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    function mintMultiple(uint256 _amountToMint)
        public
        payable
        onlyEOA
        mintingAllowed
        limitSupply(_amountToMint)
        enoughFunds(_amountToMint)
        limitTokensToHold(_amountToMint)
        limitTokensToMint(_amountToMint)
    {
        _mintMultiple(_amountToMint);
    }

    function mintReserved(uint256 _amountToMint)
        public
        onlyOwner
        limitSupply(_amountToMint)
    {
        _mintMultiple(_amountToMint);
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

    function toggleWhitelistMintingStatus() public onlyOwner {
        _isMintingAllowedWhitelist = !_isMintingAllowedWhitelist;
    }

    function setMaxAmountToMint(uint256 maxAmountToMint) public onlyOwner {
        _maxAmountToMint = maxAmountToMint;
    }

    function setMaxAmountToHold(uint256 maxAmountToHold) public onlyOwner {
        _maxAmountToHold = maxAmountToHold;
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        _itemPrice = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        _maxSupply = _supply;
    }

    function setExternalWhitelistAddress(address _address) public onlyOwner {
        externalWhitelistAddress = _address;
    }

    function addWhitelist(address _address) public onlyOwner {
        internalWhitelist[_address] = true;
    }

    function removeWhitelist(address _address) public onlyOwner {
        internalWhitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return
            internalWhitelist[_address] ||
            IExternalWhiteList(externalWhitelistAddress).isWhitelisted(
                _address
            );
    }
    
    /**
    // emergency draw
    */
    function releaseParitial() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
    // Transfer balance money to shareholders based on number of shares
    */
    function releaseAll() public onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }
}