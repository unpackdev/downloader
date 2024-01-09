//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";


contract BlackBoxAccessPass is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _accessPassCounter;
    uint public MAX_ACCESS_PASS = 3500;
    uint256 public passPrice = 1.95 ether; //1.95 ETH
    string public baseURI;
    bool public saleIsActive = false;
    uint public constant maxPassTxn = 2;
    mapping (address => uint256) passesInWallet;
    address private _manager;

    constructor() ERC721("BLACK BOX COLLECTIVE ACCESS PASS", "ACCESS PASS") Ownable() {
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

    function setMaxSupply(uint _maxSupply) public onlyOwnerOrManager {
        MAX_ACCESS_PASS = _maxSupply;
    }
    
    function setPrice(uint256 _price) public onlyOwnerOrManager {
        passPrice = _price;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _accessPassCounter.current();
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

    function reserveMintPass(uint256 reserveAmount, address mintAddress) public onlyOwnerOrManager {
        require(totalSupply() <= MAX_ACCESS_PASS, "Access Pass Sold Out");
        for (uint256 i=0; i<reserveAmount; i++){
            _safeMint(mintAddress, _accessPassCounter.current() + 1);
            _accessPassCounter.increment();
        }
    }

    function mintAccessPass(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Access Pass");
        require(passPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxPassTxn, "You can only mint 1 Access passes at a time");
        require(passesInWallet[msg.sender] <= 2,"Purchase would exeed max passes per wallet");
        require(totalSupply() + numberOfTokens <= MAX_ACCESS_PASS, "Access Passes Sold Out");

        for (uint256 i=0; i<numberOfTokens; i++){
            uint256 mintIndex = _accessPassCounter.current()+1;
            if (mintIndex <= MAX_ACCESS_PASS){
                _safeMint(msg.sender, mintIndex);
                _accessPassCounter.increment();
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