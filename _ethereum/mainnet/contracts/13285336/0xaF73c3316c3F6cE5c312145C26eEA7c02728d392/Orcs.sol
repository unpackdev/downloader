// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract OrcishRaiders is ERC721, ERC721URIStorage, Pausable, Ownable {

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;
    uint private constant maxTokensPerTransaction = 20;
    uint256 private tokenPrice = 75 * 10 ** 15; //Cost set to 0.075 ETH
    uint256 private constant nftsPublicNumber = 2711;
    address private constant withdrawAddressOne = 0x528483BD8D2963C30d303C53B2a1D0C2e512EC07;
    address private constant withdrawAddressTwo = 0x06a032A6C7675Ffd40411c5399A206C0b71aB29a;
    address private constant withdrawAddressThree = 0xAb4F661b7CBd41691887300C2BdA82568938cb82;
    bool public mainSaleActive = false;
    bool public preSaleActive = false;
    bool public whitelistSaleActive = false;
    mapping(address => bool) public preSale;
    mapping(address => bool) public whitelist;
    //Prelist Addresses
    
    Counters.Counter private _tokenIdCounter;
    
    constructor() ERC721("Orcish Raiders", "ORCS") {
        _tokenIdCounter.increment();
    }

    function currentSupply() public view returns (uint256)
    {
        return _tokenIdCounter.current();
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function addToPreSale(address[] memory _address)public onlyOwner {
       for(uint i = 0; i < _address.length; i++) {
        preSale[_address[i]]=true;
       }
    }

    function addToWhitelist(address[] memory _address)public onlyOwner {
       for(uint i = 0; i < _address.length; i++) {
        whitelist[_address[i]]=true;
       }
    }

    function flipPreSale() public onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function flipWhitelistSale() public onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function flipMainSale() public onlyOwner {
        mainSaleActive = !mainSaleActive;
    }

    function buyPreSaleOrc(uint tokensNumber) public payable {
        require(preSaleActive, "Pre-Sale Sale not Active!");
        require(tokensNumber > 0, "Number of mints must be atleast 1");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "No more tokens left to be minted");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Not enough sent ETH, price is 0.075 per token");
        require(preSale[msg.sender]==true, "Address not in the presale");
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
    }

    function buyWhitelistOrc(uint tokensNumber) public payable {
        require(whitelistSaleActive, "Whitelist Sale not Active!");
        require(tokensNumber > 0, "Number of mints must be atleast 1");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "No more tokens left to be minted");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Not enough sent ETH, price is 0.075 per token");
        require(whitelist[msg.sender]==true, "Address not in the presale");
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
    }

    function mintGiveawayOrcs(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Sale has not ended yet!");
        _safeMint(to, tokenId);
    }

    function buyOrcs(uint tokensNumber) public payable {
        require(mainSaleActive, "Whitelist Sale not Active!");
        require(tokensNumber > 0, "Number of mints must be atleast 1");
        require(tokensNumber <= maxTokensPerTransaction, "Exceeded max tokens per mint");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "No more tokens left to be minted");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Not enough sent ETH, price is 0.075 per token");
        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint cut = balance.div(3);
        payable(withdrawAddressOne).transfer(cut);
        payable(withdrawAddressTwo).transfer(cut);
        payable(withdrawAddressThree).transfer(cut);

    }
}