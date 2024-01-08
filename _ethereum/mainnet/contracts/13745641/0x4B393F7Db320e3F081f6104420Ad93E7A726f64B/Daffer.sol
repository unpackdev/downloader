// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Daffer is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;
    uint private constant maxTokensPerTransaction = 25;
    uint256 private tokenPrice = 75000000000000000; //0.075 ETH
    uint256 private constant nftsNumber = 4689;
    uint256 private constant nftsPublicNumber = 4669;
    Counters.Counter private _tokenIdCounter;
    bool public pauseValue;
    bool public presaleValue;
    address private constant DafferOne = 0x6BB1446cFAfB02C8048A85d7349001F803c14674;
    address private constant DafferTwo = 0x74d85b145A1a1531fb527aDd04d41018E12df746;
    address private constant DafferThree = 0x0F3Fd2aA740bB4C31Cb93310150949F6Ce0F3E27;
    address private constant DafferFour = 0xE50A1215319Aa37A6a484359cE928adcE9eB6e0d;
    mapping(address => bool) whitelist;

    constructor() ERC721("Daffer", "DAFFER") {
        _tokenIdCounter.increment();
    }
    function prevent() public onlyOwner {
        pauseValue = !pauseValue;
    }

    function presaleSwitch() public onlyOwner {
        presaleValue = !presaleValue;
    }

    function daffer() public pure returns (string memory){
        return "DAFFER";
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
    function howManyDaffers() public view returns(uint256 a){
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
        uint cut = balance.div(4);
        payable(DafferOne).transfer(cut);
        payable(DafferTwo).transfer(cut);
        payable(DafferThree).transfer(cut);
        payable(DafferFour).transfer(cut);
    }

    function approve(address addr) public onlyOwner {
    // owner approves buyers by address when they pass the whitelisting procedure

        whitelist[addr] = true;
    }

    function buyWhitelistDaffer(uint tokensNumber) whenNotPaused public payable {
        require (whitelist[msg.sender]);
        require (presaleValue);
        require(tokensNumber > 0, "You can't mint 0 Daffers.");
        require(tokensNumber <= maxTokensPerTransaction, "Too many!");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Sorry theres no Daffers left :(");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Thats not enough, sorry!");
        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function mintGiveawayDaffer(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Wait for the sale to end first");
        _safeMint(to, tokenId);
    }
    function buyDaffer(uint tokensNumber) whenNotPaused public payable {
        require (pauseValue);
        require(tokensNumber > 0, "You can't mint 0 Daffers.");
        require(tokensNumber <= maxTokensPerTransaction, "Too many!");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Sorry theres no Daffers left :(");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Thats not enough, sorry!");
        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}