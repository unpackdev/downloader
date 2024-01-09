//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";

import "Ownable.sol";

import "SafeMath.sol";

import "Counters.sol";

contract SpaceyChimpsNFT is ERC721("Spacey Chimps", "CHIMP"), Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public constant MAX_PER_TX = 20;
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant price = 15000000000000000;

    bool public saleIsActive;
    string public baseTokenURI;

    address
        public constant addrOne = 0x5C2D5404A278eB5A6EBB754EF8aE53345cfd4595;
    address
        public constant addrTwo = 0x82713E792d405A4befCbF956dcD7327a164BD888;
    address
        public constant addrThree = 0xf0b5b656fC8E50Ae72074C8E450BD98BCfD882e0;

    constructor() public {
        saleIsActive = false;
        setBaseURI("http://api.spaceychimps.com/");
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(
            numberOfTokens <= MAX_PER_TX,
            "Exceeds max tokens per transaction"
        );
        require(
            _tokenSupply.current().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(
            price.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenSupply.increment();
            uint256 newTokenId = _tokenSupply.current();
            _safeMint(msg.sender, newTokenId);
        }
    }

    function _baseURI() internal virtual override view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdrawSplit() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance == 0");
        _widthdraw(addrOne, balance.mul(5).div(100));
        _widthdraw(addrTwo, balance.mul(5).div(100));
        _widthdraw(addrThree, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function getPrice(uint256 _count) public view returns (uint256) {
        return price.mul(_count);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply.current();
    }
}
