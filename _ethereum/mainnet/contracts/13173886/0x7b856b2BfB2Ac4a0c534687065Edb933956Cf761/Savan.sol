// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;

import "./ERC721Tradable.sol";
import "./Counters.sol";
import "./Strings.sol";


contract Savan is ERC721Tradable{

    uint256 mintLimitPerTransaction = 15;
    uint256 maxTotalSupply = 10000;
    string private _baseUri;
    string private _stubURI;
    string public contractURI;
    bool private _sale = false;

    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    constructor(string memory baseUri, string memory contractURi, 
            string memory stubURi, address _proxyRegistry) 
            ERC721("Savan", "SAVAN") {
        _baseUri = baseUri;
        contractURI = contractURi;
        _stubURI = stubURi;
        proxyRegistry = _proxyRegistry;
    }

    modifier _isEnoughTokens(uint256 amount){
        require(_tokenIds.current() + amount <= maxTotalSupply, "Savan: more than possible minted amount");
        _;
    }

    modifier _checkAmount(uint256 amount){
        require(amount <= mintLimitPerTransaction, string(abi.encodePacked("Savan: more than possible amount per mint. Max - ", mintLimitPerTransaction.toString())));
        require(amount >= 1, "Savan: amount should be positive");
        _;
    }

    function setMintLimitPerTransaction(uint256 newmintLimitPerTransaction) public onlyOwner{
        mintLimitPerTransaction = newmintLimitPerTransaction;
    }

    function setSale(bool newSale) public onlyOwner {
        _sale = newSale;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function setContractURI(string memory contractURi) public onlyOwner {
        contractURI = contractURi;
    }

    function setStubURI(string memory stubURi) public onlyOwner {
        _stubURI = stubURi;
    }

    function stubURI() public view returns (string memory) {
        return _stubURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Savan: URI query for nonexistent token");

        if (_sale){
            return string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"));
        }
        else{
            return _stubURI; 
        }
        
    }

    function mintToken(address _to) 
        public onlyOwner {
        _mintTokens(_to, 1);
    }

    function mintTokens(address _to, uint256 amount) 
        public onlyOwner {
        _mintTokens(_to, amount);
    }

    function _mintTokens(address _to, uint256 amount)
        internal _isEnoughTokens(amount) _checkAmount(amount) {
        for (uint16 i = 0; i < amount; i++){
            _safeMint(_to, _tokenIds.current());
            _tokenIds.increment();
        }
    }

}
