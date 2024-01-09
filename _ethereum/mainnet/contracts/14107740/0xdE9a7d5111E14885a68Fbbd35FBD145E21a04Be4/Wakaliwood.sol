// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";


contract WhoKilledCaptainAlex is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;
    uint32 private constant maxTokensPerTransaction = 10;
    uint256 private tokenPrice = 3.5 * 10 ** 16; //0.035 ETH
    uint256 private constant nftsPublicNumber = 2037;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("WakaliwoodNFT", "Supa!") {
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

    function howManyClips() public view returns(uint256 a){
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

    function mintClip(uint32 tokensNumber) public payable {
        require(tokensNumber > 0, "You cant mint 0 NFTs!");
        require(tokensNumber <= maxTokensPerTransaction, "Save some for everyone else!");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "We are out of stock!");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "You are too poor for Uganda!");
        for(uint32 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}
