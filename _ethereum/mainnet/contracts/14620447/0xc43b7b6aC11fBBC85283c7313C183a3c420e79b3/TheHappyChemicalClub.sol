// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Bundle.sol";

/**
 * @title The Happy Chemical Club
 */
contract TheHappyChemicalClub is Bundle {
    receive() external payable {}
    fallback() external payable {}

    event Withdraw(address operator, address receiver, uint256 value);

    mapping(address => uint256) private _mintLimit;

    uint256 private _limit;
    uint256 private _price;
    uint256 private _freeTokensLimit;

    bool private _locked;
    bool private _mintPause;

    constructor(uint256 _freeTokens) {
        _limit = 5;
        _price = 10000000000000000;
        _locked = false;
        _mintPause = true;
        _freeTokensLimit = _freeTokens;
    }

    modifier gate() {
        require(_locked == false, "TheHappyChemicalClub: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    function mintPrice(uint256 _quantity) public view returns (uint256) {
        if (_currentTokenId() < _freeTokensLimit) {
            return 0;
        } else {
            return (_price * _quantity);
        }
    }

    function setPrice(uint256 _value) public ownership {
        _price = _value;
    }

    function unpause() public ownership {
        _mintPause = false;
    }

    function pause() public ownership {
        _mintPause = true;
    }

    function paused() public view returns (bool) {
        return _mintPause;
    }

    function setRevealURI(string memory _cid, bool _isExtension) public ownership {
        _setRevealURI(_cid, _isExtension);
    }

    function checkURI(uint256 _tokenId) public view returns (string memory) {
        return _checkURI(_tokenId);
    }

    function reveal() public ownership {
        _reveal();
    }

    function setMintLimit(uint256 _amount) public ownership {
        _limit = _amount;
    }

    function mintLimit() public view returns (uint256) {
        if (_currentTokenId() < _freeTokensLimit) {
            return 1;
        } else {
            return _limit;
        }
    }

    function mint(uint256 _quantity) public payable gate {
        require(msg.value >= mintPrice(_quantity), "TheHappyChemicalClub: not enough funds provided");
        require(_quantity + totalSupply() <= 4200, "TheHappyChemicalClub: maximum tokens minted");
        require(_quantity <= mintLimit(), "TheHappyChemicalClub: tokens exceed mint limit");
        require(_quantity + _mintLimit[msg.sender] <= mintLimit(), "TheHappyChemicalClub: tokens exceed mint limit");
        require(_mintPause != true, "TheHappyChemicalClub: minting is paused");
        _mintLimit[msg.sender] += _quantity;
        for (uint256 i=0; i < _quantity; i++) {
            _mint(msg.sender);
        }
    }

    function airdropBatch(address[] memory _to) public ownership {
        require(_to.length + totalSupply() <= 4200, "TheHappyChemicalClub: maximum tokens minted");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i]);
        }
    }

    function airdrop(address _to, uint256 _quantity) public ownership {
        require(_quantity + totalSupply() <= 4200, "TheHappyChemicalClub: maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mint(_to);
        }
    }

    function withdraw(address _account) public ownership {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_account).call{value: address(this).balance}("");
        require(success, "TheHappyChemicalClub: ether transfer failed");

        emit Withdraw(msg.sender, _account, balance);
    }
}
