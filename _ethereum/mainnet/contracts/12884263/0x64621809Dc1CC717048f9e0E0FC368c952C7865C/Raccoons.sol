// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Raccoons is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI = "";
    uint256 private _reserved = 100;
    uint256 private _price = 0.08 ether;
    bool public _paused = true;

    // withdraw addresses
    address t1 = 0x74D9DfC0b216C82d3bdC2a5E63E5CDc172eD893b;
    address t2 = 0x99d57de496D83Baa6203f1Fa78cd07cbf37b9b8C;
    address t3 = 0x1E1cE89BFdF73e978f505bfA3e8d226DbE9a5b41;

    modifier canWithdraw(){
        require(address(this).balance > 0.2 ether);
        _;
    }

    struct ContractOwners {
        address payable addr;
        uint percent;
    }

    ContractOwners[] contractOnwers;

    constructor() ERC721("Raccoons", "RACC")  {
        // The team gets the first 3 Raccoons
        _safeMint( t1, 0);
        _safeMint( t2, 1);
        _safeMint( t3, 2);
        contractOnwers.push(ContractOwners(payable(address(t1)), 45));
        contractOnwers.push(ContractOwners(payable(address(t2)), 45));
        contractOnwers.push(ContractOwners(payable(address(t3)), 10));
    }

    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can adopt a maximum of 20 Raccoons" );
        require( supply + num < 10000 - _reserved,      "Exceeds maximum Raccoons supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // In case ETH goes wild
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Raccoons supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdraw() external payable onlyOwner() canWithdraw() {
        uint nbalance = address(this).balance - 0.1 ether;
        for(uint i = 0; i < contractOnwers.length; i++){
            ContractOwners storage o = contractOnwers[i];
            o.addr.transfer((nbalance * o.percent) / 100);
        }
    }
}
