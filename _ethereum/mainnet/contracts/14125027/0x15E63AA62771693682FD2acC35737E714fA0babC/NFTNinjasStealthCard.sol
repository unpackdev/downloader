//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract NFTNinjasStealthCard is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _cardCounter;
    uint public MAX_CARD = 100;
    string public baseURI;
    address private _manager;

    constructor() ERC721("NFT NINJAS", "STEALTH CARD"){
    }

    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }
    
    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwnerOrManager {
        baseURI = newBaseURI;
    }

    function setMaxNinja(uint newMaxNinja) public onlyOwnerOrManager{
        MAX_CARD = newMaxNinja;
    }
    
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _cardCounter.current();
    }

    function reserveMintNinja(uint256 reserveAmount, address mintAddress) public onlyOwnerOrManager {
        require(totalSupply() <= MAX_CARD, "Mint would exceed max supply of Stealth Cards");
        for (uint256 i=0; i<reserveAmount; i++){
            _safeMint(mintAddress, _cardCounter.current() + 1);
            _cardCounter.increment();
        }
    }

    function withdrawForOwner(address payable to) public payable onlyOwnerOrManager{
        to.transfer(address(this).balance);
    }

    function withdrawAll(address _address) public onlyOwnerOrManager {
        uint256 balance = address(this).balance;
        require(balance > 0,"Balance is zero");
        (bool success, ) = _address.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _widthdraw(address _address, uint256 _amount) public onlyOwnerOrManager{
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}