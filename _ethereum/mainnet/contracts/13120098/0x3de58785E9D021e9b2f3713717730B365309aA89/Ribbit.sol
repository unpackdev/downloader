// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Ribbit is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;
    uint private constant maxTokensPerTransaction = 50;
    uint256 private tokenPrice = 25000000000000000; //0.025 ETH
    uint256 private constant nftsNumber = 3025;
    uint256 private constant nftsPublicNumber = 3000;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RibBits", "RIBBIT") {
        _tokenIdCounter.increment();
    }
    function ribbit() public pure returns (string memory){
        return "RIBBIT";
    }
    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function howManyFrawg() public view returns(uint256 a){
       return Counters.current(_tokenIdCounter);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
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
   function mintGiveawayFrawgs(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Wait for the sale to end first, stoopid");
        _safeMint(to, tokenId);
    }
    function buyFrawgs(uint tokensNumber) whenNotPaused public payable {
        require(tokensNumber > 0, "U cant mint zero frogs bro");
        require(tokensNumber <= maxTokensPerTransaction, "Save some for everyone else!");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Sry I dont have enough left ;(");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "That's not enough, sry ;(");
        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}