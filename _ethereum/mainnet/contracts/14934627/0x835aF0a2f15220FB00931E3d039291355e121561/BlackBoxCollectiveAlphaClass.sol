//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract BlackBoxCollectiveAlphaClass is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _alphaClassCounter;
    uint public MAX_ALPHA_CLASS = 50;
    uint256 public passPrice = 5 ether; 
    string public baseURI;
    bool public saleIsActive = false;
    uint public maxPassTxn = 1;
    mapping (address => uint256) passesInWallet;
    address public _manager;

    constructor() ERC721("BLACK BOX COLLECTIVE", "ALPHA CLASS") Ownable() {
    }
    
    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }
    
    function getManager() public view onlyOwnerOrManager returns (address){
        return _manager;
    }
    
    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwnerOrManager {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint _maxSupply) public onlyOwnerOrManager {
        MAX_ALPHA_CLASS = _maxSupply;
    }
    
    function setPrice(uint256 _price) public onlyOwnerOrManager {
        passPrice = _price;
    }

    function setMaxTxn(uint _maxPassTxn) public onlyOwnerOrManager {
        maxPassTxn = _maxPassTxn;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _alphaClassCounter.current();
    }
    
    function contractBalance() public view onlyOwnerOrManager returns (uint256) {
        return address(this).balance;
    }

    function flipSale() public onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function stateSale() public view returns (bool){
        return saleIsActive;
    }

    function withdrawAll(address _address) public onlyOwnerOrManager {
        uint256 balance = address(this).balance;
        require(balance > 0,"Balance is zero");
        (bool success, ) = _address.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _withdraw(address _address, uint256 _amount) public onlyOwnerOrManager{
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function reserveMintPass(uint256 reserveAmount, address mintAddress) public onlyOwnerOrManager {
        require(totalSupply() + reserveAmount <= MAX_ALPHA_CLASS, "Alpha Class Sold Out");
        for (uint256 i=0; i<reserveAmount; i++){
            _safeMint(mintAddress, _alphaClassCounter.current() + 1);
            _alphaClassCounter.increment();
        }
    }

    function mintAlphaPass(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Alpha Class");
        require(passPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxPassTxn, "You can only mint 1 Alpha Class at a time");
        require(passesInWallet[msg.sender] <= 1,"Purchase would exeed max passes per wallet");
        require(totalSupply() + numberOfTokens <= MAX_ALPHA_CLASS, "Alpha Class Sold Out");

        for (uint256 i=0; i<numberOfTokens; i++){
            uint256 mintIndex = _alphaClassCounter.current()+1;
            if (mintIndex <= MAX_ALPHA_CLASS){
                _safeMint(msg.sender, mintIndex);
                _alphaClassCounter.increment();
                passesInWallet[msg.sender] += 1;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}