// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract UnicornMultiverse is ERC721Enumerable, Ownable, Pausable {
    string _baseTokenURI;

    uint256 private _maxTokenCount = 10000;
    uint256 private _reserved = 400;
    uint256 private _presaleLeft = 1000;
    uint256 public constant price = 0.05 ether;
    uint256 public constant presalePrice = 0.03 ether;

    bool private _presale = true;
    
    mapping(address => bool) public whitelist;

    address t1 = 0x2A71996Eb62E15f76C78d90B6ce901527e47aB0D; // Arthur
    address t2 = 0xc1490e6608b18724300034dfE5775ea0f3eb490e; // Kirill
    address t3 = 0x3570c9572Ec101f220196a275E7F57c5FfBD3f47; // Egor
    address t4 = 0x7Fb3bf58D69b4d953c081966f28c639a2A95975A; // Artem
    address t5 = 0xA2498e4120153833E717829E53eF290C59442111; // Dima
    address t6 = 0xe61d2C0De98315959B536D5243ac4583FaC84332; // Nikolas

    modifier whenPresale() {
        require(_presale, "Presale closed");
        _;
    }

    modifier whenNotPresale() {
        require(!_presale, "Sale closed");
        _;
    }

    constructor(string memory baseTokenURI) ERC721("Unicorn Multiverse", "UCMV")  {
        setBaseURI(baseTokenURI);
    }

    function mintUnicorn(uint256 _amount) public payable whenNotPaused whenNotPresale {
        require(_amount <= 20, "Can only mint 20 tokens at a time");
        require(totalSupply() + _amount <= _maxTokenCount - _reserved, "Exceeds maximum Unicorns supply");
        require(msg.value >= price * _amount, "Ether value sent is not correct");

        for(uint256 i = 0; i < _amount; i++) {
            uint mintIndex = totalSupply() + 1;
            if (totalSupply() < _maxTokenCount) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function presaleUnicorn(uint256 _amount) public payable whenNotPaused whenPresale {
        require(whitelist[msg.sender], "Not whitelisted for private sale");
        require(_amount <= _presaleLeft, "Exceeds presale Unicorn supply");
        require(_amount <= 20, "Can only mint 20 tokens at a time");
        require(totalSupply() + _amount <= _maxTokenCount - _reserved, "Exceeds maximum Unicorns supply");
        require(msg.value >= presalePrice * _amount, "Ether value sent is not correct");

        for(uint256 i = 0; i < _amount; i++) {
            uint mintIndex = totalSupply() + 1;
            if (totalSupply() < _maxTokenCount) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        _presaleLeft -= _amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function giveAway(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_amount <= _reserved, "Exceeds reserved Unicorn supply");

        for(uint256 i = 1; i <= _amount; i++) {
            uint mintIndex = totalSupply() + 1;
            if (totalSupply() < _maxTokenCount) {
                _safeMint(_to, mintIndex);
            }
        }

        _reserved -= _amount;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance / 100;

        require(payable(t1).send(_balance * 23));
        require(payable(t2).send(_balance * 22));
        require(payable(t3).send(_balance * 27));
        require(payable(t4).send(_balance * 10));
        require(payable(t5).send(_balance * 13));
        require(payable(t6).send(_balance * 5));
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for(uint256 i; i < _addresses.length; i ++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        delete whitelist[_address];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function presale() public view returns(bool) {
        return _presale;
    }

    function setPresale(bool value) public onlyOwner {
        _presale = value;
    }
}