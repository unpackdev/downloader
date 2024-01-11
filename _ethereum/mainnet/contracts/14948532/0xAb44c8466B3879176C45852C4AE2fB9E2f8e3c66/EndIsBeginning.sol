// SPDX-License-Identifier: MIT

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// █▀▀ █▀▀▄ █▀▀▄       ░▀░ █▀▀       █▀▀▄ █▀▀ █▀▀▀ ░▀░ █▀▀▄ █▀▀▄ ░▀░ █▀▀▄ █▀▀▀ ////////////////////////
//////////////////////////// █▀▀ █░░█ █░░█       ▀█▀ ▀▀█       █▀▀▄ █▀▀ █░▀█ ▀█▀ █░░█ █░░█ ▀█▀ █░░█ █░▀█ ////////////////////////
//////////////////////////// ▀▀▀ ▀░░▀ ▀▀▀░       ▀▀▀ ▀▀▀       ▀▀▀░ ▀▀▀ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀░░▀ ▀▀▀ ▀░░▀ ▀▀▀▀ ////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// author: acid-deployer.eth

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract EndIsBeginning is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.02 ether;
    uint256 public MAX_SUPPLY = 3001;
    
    uint256 public MAX_MINT_FOR_TXN = 101;

    string private BASE_URI = '';

    bool public REVEAL_STATUS = false;

    uint256 public FREE_MINT_LIMIT = 1000;

    constructor() ERC721A("EndIsBeginning", "EndIsBeginning") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setRevealStatus(bool revealStatus) external onlyOwner {
        REVEAL_STATUS = revealStatus;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount < MAX_MINT_FOR_TXN, "Invalid mint amount!");
        require(currentIndex + _mintAmount < MAX_SUPPLY, "Max supply exceeded!");
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        if (currentIndex + _mintAmount > FREE_MINT_LIMIT) {
            uint256 price = PRICE * _mintAmount;
            require(msg.value >= price, "Insufficient funds!");
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAdd =
    0xbA9c2BAa2eC68ac85172591Ed9b2236f127AE337;

    function endisbegin() public onlyOwner nonReentrant {
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
            return 'https://gateway.pinata.cloud/ipfs/QmcyaWtpQ99sp9sbUdqp27wz9hJT7y9ZDPR1D7q4gefjhK';
        }
    }
}