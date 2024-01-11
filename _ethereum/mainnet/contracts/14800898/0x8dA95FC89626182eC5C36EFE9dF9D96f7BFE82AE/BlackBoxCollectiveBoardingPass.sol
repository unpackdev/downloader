//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract BlackBoxCollectiveBoardingPass is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _boardingPassCounter;
    uint public MAX_BOARDING_PASS = 500;
    uint256 public passPrice = .08 ether;
    string public baseURI;
    bool public saleIsActive = false;
    uint public constant maxPassTxn = 10;
    address private _manager;

    constructor() ERC721("BLACK BOX COLLECTIVE", "BOARDING PASS") Ownable() {
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
        MAX_BOARDING_PASS = _maxSupply;
    }
    
    function setPrice(uint256 _price) public onlyOwnerOrManager {
        passPrice = _price;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _boardingPassCounter.current();
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

    function _widthdraw(address _address, uint256 _amount) public onlyOwnerOrManager{
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function reserveMintPass(uint256 reserveAmount, address mintAddress) public onlyOwnerOrManager {
        require(totalSupply() + reserveAmount <= MAX_BOARDING_PASS, "Boarding Pass Sold Out");
        for (uint256 i=0; i<reserveAmount; i++){
            _safeMint(mintAddress, _boardingPassCounter.current() + 1);
            _boardingPassCounter.increment();
        }
    }

    function mintBoardingPass(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Boarding Pass");
        require(passPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxPassTxn, "You can only mint 10 Boarding passes at a time");
        require(totalSupply() + numberOfTokens <= MAX_BOARDING_PASS, "Boarding Passes Sold Out");

        for (uint256 i=0; i<numberOfTokens; i++){
            uint256 mintIndex = _boardingPassCounter.current()+1;
            if (mintIndex <= MAX_BOARDING_PASS){
                _safeMint(msg.sender, mintIndex);
                _boardingPassCounter.increment();
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