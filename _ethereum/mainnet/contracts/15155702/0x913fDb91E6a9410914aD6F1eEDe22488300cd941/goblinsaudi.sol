// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract saudigoblins is ERC721A, Ownable {

    uint256 MAX_MINTS = 3; 
    uint256 MAX_WHITELIST = 2;
    uint256 MAX_SUPPLY = 1111;
    mapping(address => uint8) private _whitelist;
    bool public whitelistOpen = false;
    bool public mintingOpen = false;
    bool public isRevealed = false;
    uint256 public mintRate = 0 ether;
    string public baseURI = "ipfs://placeholder/";
    constructor() ERC721A("The Saudi Goblins", "SAUDIGOBLINS") {}

    function mint(uint256 quantity) external payable {
        require(mintingOpen, "Public sale closed");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }
    function mintWL(uint256 quantity) external payable {
        require(whitelistOpen, "Whitelist sale closed");
        require(quantity + _numberMinted(msg.sender) <= MAX_WHITELIST, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(quantity + _numberMinted(msg.sender) <= _whitelist[msg.sender], "You are trying to buy more then you can claim. Please fix the amount");     
        _safeMint(msg.sender, quantity);
    }

    function mintTo(uint256 quantity,address to) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");   
        _safeMint(to, quantity);
    }  
    function claimableMints(address checkAdress) external returns (uint256) {

        return _whitelist[checkAdress] - _numberMinted(checkAdress);

    }
    function checkMinted(address checkAdress) external returns (uint256) {
        return _numberMinted(checkAdress);

    }
    function burn(uint256 tokenId)  public onlyOwner {
        _burn(tokenId, false);
    }

    function setWhitelist(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] =  numAllowedToMint;
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
        whitelistOpen = true;
    }

    function stopMinting() public onlyOwner {
        mintingOpen = false;
    }

    function stopFreeSale() public onlyOwner {
        whitelistOpen = false;
    }
    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function set_MAX_MINTS(uint256 _amount) public onlyOwner {
        MAX_MINTS = _amount;
    }
    function set_MAX_WHITELIST(uint256 _amount) public onlyOwner {
        MAX_WHITELIST = _amount;
    }

    function set_MAX_SUPPLY(uint256 _amount) public onlyOwner {
        MAX_SUPPLY = _amount;
    }
}