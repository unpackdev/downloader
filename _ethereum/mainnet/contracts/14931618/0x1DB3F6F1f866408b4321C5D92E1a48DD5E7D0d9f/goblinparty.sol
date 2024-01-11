// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract goblinparty is ERC721A, Ownable {

    uint256 MAX_MINTS = 20; // 
    uint256 MAX_FREEMINTS = 6;
    uint256 MAX_SUPPLY = 2222;
    uint256 MAX_PUBLIC = 1800;
    mapping(address => uint8) private _freeList;
    bool public freeSaleOpen = true;
    bool public mintingOpen = true;
    bool public isRevealed = false;
    bool public discountActive = true;
    uint256 public mintRate = 0.035 ether;
    uint256 private buy3 = 94;
    uint256 private buy5 = 89;
    uint256 private buy7 = 84;
    uint256 private buy10 = 79;
    string public baseURI = "";
    constructor() ERC721A("goblinparty.wtf", "GPARTY") {}

    function mint(uint256 quantity) external payable {
        uint256 finalprice = (mintRate*quantity);                   
        require(mintingOpen, "Publicsale closed");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_PUBLIC, "Exceeded the public allocation limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        if (discountActive) {
            if (quantity >= 3) {
                finalprice = finalprice * (buy3/100);
            } else if (quantity >= 5) {
                finalprice = finalprice * (buy5/100);
            } else if (quantity >= 7) {
                finalprice = finalprice * (buy7/100);
            } else if (quantity == 10) {
                finalprice = finalprice * (buy10/100);
            }
        }   
        require(msg.value >= (finalprice), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }
    function freeMint(uint256 quantity) external payable {
        require(freeSaleOpen, "Free mint closed");
        require(quantity + _numberMinted(msg.sender) <= MAX_FREEMINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(quantity + _numberMinted(msg.sender) <= _freeList[msg.sender], "You are trying to buy more then you can claim. Please fix the amount");     
        _safeMint(msg.sender, quantity);
    }
    function doReveal(string calldata setURI) public onlyOwner() {
        isRevealed = true;
        baseURI= setURI;
    }
    function unReveal(string calldata setURI) public onlyOwner() {
        isRevealed = false;
        baseURI= setURI;
    }
    function mintTo(uint256 quantity,address to) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");   
        _safeMint(to, quantity);
    }  
    function claimableMints(address checkAdress) external returns (uint256) {

        return _freeList[checkAdress] - _numberMinted(checkAdress);

    }
    function checkMinted(address checkAdress) external returns (uint256) {
        return _numberMinted(checkAdress);

    }
    function burn(uint256 tokenId)  public onlyOwner {
        _burn(tokenId, false);
    }

    function setFreeList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeList[addresses[i]] =  numAllowedToMint;
        }
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
   
    function setBaseURI(string calldata setURI) external onlyOwner() {
        baseURI= setURI;
    }
 
    function openMinting() public onlyOwner {
        mintingOpen = true;
    }
    
    function openFreeSale() public onlyOwner {
        freeSaleOpen = true;
    }

    function stopMinting() public onlyOwner {
        mintingOpen = false;
    }

    function stopFreeSale() public onlyOwner {
        freeSaleOpen = false;
    }
    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }
    function setDiscountActive() public onlyOwner {
        discountActive = true;
    }
    function setDiscountInactive() public onlyOwner {
        discountActive = false;
    }
    function set_MAX_MINTS(uint256 _amount) public onlyOwner {
        MAX_MINTS = _amount;
    }
    function set_MAX_FREEMINTS(uint256 _amount) public onlyOwner {
        MAX_FREEMINTS = _amount;
    }
    function set_MAX_PUBLIC(uint256 _amount) public onlyOwner {
        MAX_PUBLIC = _amount;
    }
    function set_MAX_SUPPLY(uint256 _amount) public onlyOwner {
        MAX_SUPPLY = _amount;
    }
}