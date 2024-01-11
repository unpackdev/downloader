// SPDX-License-Identifier: MIT

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////█▀▄▀█ █▀▀ █▀▀ █▀▀█ █▀▀   █▀▀█ █▀▀▄   █▀▀█ █▀▀ ░▀░ █▀▀▄////////////////////////////
////////////////////////////█░▀░█ █▀▀ █▀▀ █▄▄▀ ▀▀█   █░░█ █░░█   █▄▄█ █░░ ▀█▀ █░░█////////////////////////////
////////////////////////////▀░░░▀ ▀░░ ▀▀▀ ▀░▀▀ ▀▀▀   ▀▀▀▀ ▀░░▀   ▀░░▀ ▀▀▀ ▀▀▀ ▀▀▀░////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract AcidMfers is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.0069 ether;
    uint256 public MAX_SUPPLY = 1555;
    
    uint256 public MAX_MINT_FOR_TXN = 100;

    string private BASE_URI = '';

    bool public REVEAL_STATUS = false;

    constructor() ERC721A("AcidMfers", "AcidMfers") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }

    function setMaxSupply(uint256 value) external onlyOwner {
        MAX_SUPPLY = value;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setMaxMintForTxn(uint256 value) external onlyOwner {
        MAX_MINT_FOR_TXN = value;
    }

    function setRevealStatus(bool revealStatus) external onlyOwner {
        REVEAL_STATUS = revealStatus;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= MAX_MINT_FOR_TXN, "Invalid mint amount!");
        require(currentIndex + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        uint256 price = PRICE * _mintAmount;
        require(msg.value >= price, "Insufficient funds!");
        
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAdd =
    0xbA9c2BAa2eC68ac85172591Ed9b2236f127AE337;

    function tripping() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAdd), balance);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory) 
    {
        require(_exists(tokenId), "Non-existent token!");
        if(REVEAL_STATUS) {
            string memory baseURI = BASE_URI;
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        } else {
            return 'https://gateway.pinata.cloud/ipfs/QmPTeWwNoyERAkWoazdFQ3E5pmGQ5RvneSBeaj6V9yHGjh';
        }
    }
}