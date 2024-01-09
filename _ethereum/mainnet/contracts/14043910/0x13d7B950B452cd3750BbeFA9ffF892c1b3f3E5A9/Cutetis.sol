// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract Cutetis is ERC721A, Ownable {
    using Strings for uint256;
    
    //token Index tracker 
    //supply counters 
    
    uint256 public totalCount;


    uint256 public maxBatch;
    uint256 public price = 50000000000000000;

    //string
    string public baseURI;

    
    // Minting sale state
    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN
    }
    SaleState saleState = SaleState.CLOSED;

    // Whitelist token allowances
    mapping(address => uint256) presaleAllowance;

    //constructor args 
    constructor(string memory baseURI_, uint256 maxBatchSize_, uint256 collectionSize_) ERC721A("Cutetis", "Cutetis",maxBatchSize_,collectionSize_) {
        baseURI = baseURI_;
        totalCount = collectionSize_;
        maxBatch = maxBatchSize_;
    }

    function setPresaleAllowance(address _to, uint256 _allowance)
        public
        onlyOwner
    {
        presaleAllowance[_to] = _allowance;
    }

    function setPresaleAllowances(address[] memory _to, uint256 _allowance)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            presaleAllowance[_to[i]] = _allowance;
        }
    }

    function getPresaleAllowance(address _to) public view returns (uint256) {
        return presaleAllowance[_to];
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return presaleAllowance[_account] > 0;
    }

    function isWhitelisted(address _account, uint256 _count)
        public
        view
        returns (bool)
    {
        return presaleAllowance[_account] >= _count;
    }

    function setSaleState(uint8 _state) public onlyOwner {
        saleState = SaleState(_state);
    }

    function getSaleState() public view returns (uint8) {
        return uint8(saleState);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }



    function getSupply() public view returns (uint256) {
        return totalCount;
    }

    function setSupply(uint256 _newSupply) public onlyOwner {
        totalCount = _newSupply;
    }

    //basic functions. 
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    //erc721 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    
    // Need ERC721A to get tokenOfOWnerByIndex for staking
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    // Presale mint
    function presaleMint(uint256 _times) public payable {
        require(saleState == SaleState.PRESALE, "Not in presale");
        uint256 totalPrice = price * _times;
        require(msg.value == totalPrice,"Wrong input price");
        require(totalSupply() + _times <= totalCount, "Max supply reached");
        require(isWhitelisted(msg.sender, _times),"Insufficient reserved tokens");

        payable(owner()).transfer(msg.value);

       
        _safeMint(msg.sender, _times);
        presaleAllowance[msg.sender] -= _times;

        
    }


    // Public mint
    function publicMint(uint256 _times) payable public {
        require(saleState == SaleState.OPEN, "Sales are closed to public");
        require(_times >0 && _times <= maxBatch, "Exceeded Max Batch");
        require(totalSupply() + _times <= totalCount, "Max supply reached");

        uint256 totalPrice = _times * price;

        require(msg.value == totalPrice, "Price not equal amount paid");

        payable(owner()).transfer(msg.value);

        _safeMint(msg.sender, _times);
    }  

    // For gifting & creating collection
    function giftTo(uint256 _times, address _to) public onlyOwner {
        require(totalSupply() + _times <= totalCount, "Max supply reached");
        _safeMint(_to, _times);
    }

    // Withdraw. Not really needed
    function withdrawMoney() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

}