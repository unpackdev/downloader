// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Waifu is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;
    uint private constant maxTokensPerTransaction = 50;
    uint256 private tokenPrice = 3500000000000000; //0.035 ETH
    uint256 private constant nftsNumber = 5025;
    uint256 private constant nftsPublicNumber = 5000;
    Counters.Counter private _tokenIdCounter;
    bool public pauseValue;

    constructor() ERC721("WaifuMaterial", "WAIFU") {
        _tokenIdCounter.increment();
    }
    function prevent() public onlyOwner {
        pauseValue = !pauseValue;
    }
    function waifu() public pure returns (string memory){
        return "WAIFU";
    }
    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    function safeMint(address to) public onlyOwner {
        require (_tokenIdCounter.current() <= nftsNumber, "Nice try.");
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function howManyWaifu() public view returns(uint256 a){
       return Counters.current(_tokenIdCounter);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
   function mintGiveawayWaifu(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Wait for the sale to end first");
        _safeMint(to, tokenId);
    }
    function buyWaifu(uint tokensNumber) whenNotPaused public payable {
        require (pauseValue);
        require(tokensNumber > 0, "You can't mint 0 Catgirls bro");
        require(tokensNumber <= maxTokensPerTransaction, "Woah easy there, save some for others");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Sorry theres no Catgirls left :(");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Thats not enough, sorry!");
        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}