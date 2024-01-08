// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Cyclops is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string private _baseURIPrefix;
    uint private constant maxTokensPerTransaction = 50;
    uint256 private tokenPrice = 15000000000000000; //0.035 ETH
    uint256 private constant nftsNumber = 4124;
    uint256 private constant nftsPublicNumber = 4104;
    Counters.Counter private _tokenIdCounter;

    event Buy(uint tokensNumber);
    event Pause();
    event Unpause();

    constructor() ERC721("Cyclops", "CYP") {
        _pause();
        _tokenIdCounter.increment();
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause();
        emit Pause();
    }

    function unpause() public onlyOwner {
        _unpause();
        emit Unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function directMint(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Tokens number to mint must exceed number of public tokens");
        _safeMint(to, tokenId);
    }

    function buy(uint tokensNumber) whenNotPaused public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber + 1, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        emit Buy(tokensNumber);
    }


    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
    }

    function getMaxTokensPerTransaction() public pure returns (uint){
        return maxTokensPerTransaction;
    }

    function getTokenPrice() public view returns (uint256){
        return tokenPrice;
    }

    function getNftsNumber() public pure returns (uint256){
        return nftsNumber;
    }

    function getNftsPublicNumber() public pure returns (uint256){
        return nftsPublicNumber;
    }

    function getTokenIdCounter() public view returns (uint256){
        return _tokenIdCounter.current();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}