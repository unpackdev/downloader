//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract Menace is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _menaceCounter;
    uint public MAX_MENACE = 10000;
    uint public PRESALE_MAX_MENACE = 1500;
    uint256 public menacePrice = 200000000000000000;
    uint256 public presalePrice = 99000000000000000;
    string public baseURI;
    bool public saleIsActive = false;
    bool public presaleIsActive = false;
    uint public constant maxMenaceTxn = 5;
    address private _manager;

    mapping(address => uint256) whitelistMintCount;

    constructor() ERC721("MenaceWorld", "MENACE WORLD"){
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
    
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _menaceCounter.current();
    }

    function whitelistMenaceMinted(address _address) public view returns (uint256){
        return whitelistMintCount[_address];
    }

    function flipPreSale() public onlyOwnerOrManager {
        presaleIsActive = !presaleIsActive;
    }

    function preSaleState() public view returns (bool){
        return presaleIsActive;
    }

    function flipSale() public onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function saleState() public view returns (bool){
        return saleIsActive;
    }

    function setPrice(uint256 _price) public  onlyOwnerOrManager{
        menacePrice = _price;
    }

    function setPresalePrice(uint256 _price) public onlyOwnerOrManager{
        presalePrice = _price;
    }

    function withdrawForOwner(uint256 amount, address payable to) public payable onlyOwnerOrManager{
        require(address(this).balance >= amount, "Insufficent funds.");
        uint256 payment = amount * 10 ** 18;
        to.transfer(payment);
    }

    function reserveMintMenace(uint256 reserveAmount, address mintAddress) public onlyOwnerOrManager {
        require(totalSupply() <= MAX_MENACE, "Purchase would exceed max supply of Menaces");
        for (uint256 i=0; i<reserveAmount; i++){
            _safeMint(mintAddress, _menaceCounter.current() + 1);
            _menaceCounter.increment();
        }
    }

    function mintMenaceWhitelist(uint256 numberOfTokens) public payable {
        require(presaleIsActive, "Presale must be active to mint Menaces");
        require(menacePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxMenaceTxn, "You can only mint 5 Menaces at a time");
        require(whitelistMintCount[msg.sender] + numberOfTokens <= maxMenaceTxn, "Purchase would exceed the whitelist wallet limit");
        require(totalSupply() + numberOfTokens <= PRESALE_MAX_MENACE, "PRESALE SOLD OUT");

        for (uint256 i=0; i<numberOfTokens; i++){
            uint256 mintIndex = _menaceCounter.current()+1;
            if (mintIndex <= MAX_MENACE){
                _safeMint(msg.sender, mintIndex);
                _menaceCounter.increment();
                whitelistMintCount[msg.sender] += 1;
            }
        }
    }

    function mintMenace(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Menaces");
        require(menacePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxMenaceTxn, "You can only mint 5 Menaces at a time");
        require(totalSupply() + numberOfTokens <= MAX_MENACE, "MENACES SOLD OUT");

        for (uint256 i=0; i<numberOfTokens; i++){
            uint256 mintIndex = _menaceCounter.current()+1;
            if (mintIndex <= MAX_MENACE){
                _safeMint(msg.sender, mintIndex);
                _menaceCounter.increment();
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