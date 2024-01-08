// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

contract DerpyDragons is Ownable, PaymentSplitter, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) teamWhitelist;

    string private _apiURI = "";
    uint256 public _maxSupply = 10000;
    uint256 public _maxAmountToMint = 20;
    bool public isMintingAllowed = false;
    uint256 public _itemPrice = 0.035 ether;

    uint256[] private _shares = [10,10,10,10,10,10,10,10,10,10];
    address[] private _shareholders = [
       0x0c56dE4f84EfD4f99Da9bB17f420c4170FC6CA78,  
       0x58a81b82A60586Bd3e2B3f3D5542F089e767E169,  
       0xa492605BeE17582a13F8274caa326Ff8317FB392,  
       0xCf788337CBF373379C2704443ef5c03984e213d0, 
       0x670AA7515d81682094a50bB21FdEfbfaB12930dE, 
       0x8672aDa837C557fF4A039677299D65EB0681d8A7, 
       0xebbb89656A3d5497396fA74C72dD90128162b055, 
       0x729EF50447117dCF57a60D971CF4C36840FD2559, 
       0x788f4a9b99ED6e220E901E3F0aBE80B93D14C04a, 
        0xe3f6928389E3BcC0E0b48CBa3d51903861B0a53C // DERPY SAFE
    ];

    modifier mintingAllowed() {
        require(
            isMintingAllowed || isWhitelisted(msg.sender),
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

    modifier limitTokens(uint256 _amountToMint) {
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
        ERC721("Derpy Dragons", "DERP")
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
        limitTokens(_amountToMint)
        enoughFunds(_amountToMint)
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
        isMintingAllowed = !isMintingAllowed;
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

    function addWhitelist(address _address) public onlyOwner {
        teamWhitelist[_address] = true;
    }

    function removeWhitelist(address _address) public onlyOwner {
        teamWhitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return teamWhitelist[_address];
    }

    /**
        @dev Transfer balance money to shareholders based on number of shares
     */
    function releaseAll() public onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }
    /**
        @dev emergency draw
    */
    function releaseParitial() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}