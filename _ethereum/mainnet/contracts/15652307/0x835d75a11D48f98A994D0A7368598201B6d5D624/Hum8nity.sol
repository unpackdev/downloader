// SPDX-License-Identifier: MIT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////// __                    ______         __ __         //////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////|  |--.--.--.--------.|  __  |.-----.|__|  |_.--.--.//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////|     |  |  |        ||  __  ||     ||  |   _|  |  |//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////|__|__|_____|__|__|__||______||__|__||__|____|___  |//////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Hum8nity is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.005 ether;

    string private BASE_URI = '';

    constructor() ERC721A("Hum8nity", "HUM8NITY") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }


    //MAX LIMIT PER WALLET IS 2
    //MAX SUPPLY: 1111
    function mintByUser(uint256 _mintAmount) public payable {
        require(
            _mintAmount + _numberMinted(msg.sender) < 3,
            "Max mint limit exceeded"
        );
        require(currentIndex + _mintAmount < 1112, "Max supply exceeded!");
        uint256 price = PRICE * _mintAmount;
        require(msg.value >= price, "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);
    }

    function airdrop(address _to, uint256 _mintAmount) public onlyOwner {
        require(currentIndex + _mintAmount < 1112, "Max supply exceeded!");
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAdd =
    0xFf24EF8ECa70C1441DA020d5f2ba7AD2723d2954;

    function withdraw() public onlyOwner nonReentrant {
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
        string memory baseURI = BASE_URI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        
    }
}