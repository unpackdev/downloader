// SPDX-License-Identifier: MIT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////// ███▄    █  ▒█████  ▄▄▄█████▓ ▒█████   ██ ▄█▀▄▄▄     ▓██   ██▓ ███▄ ▄███▓ █    ██ ▄▄▄█████▓ ▄▄▄       ███▄    █ ▄▄▄█████▓  ██████/////////////////////////////////
////////////////////////////██ ▀█   █ ▒██▒  ██▒▓  ██▒ ▓▒▒██▒  ██▒ ██▄█▒▒████▄    ▒██  ██▒▓██▒▀█▀ ██▒ ██  ▓██▒▓  ██▒ ▓▒▒████▄     ██ ▀█   █ ▓  ██▒ ▓▒▒██    ▒///////////////////////////////// 
///////////////////////////▓██  ▀█ ██▒▒██░  ██▒▒ ▓██░ ▒░▒██░  ██▒▓███▄░▒██  ▀█▄   ▒██ ██░▓██    ▓██░▓██  ▒██░▒ ▓██░ ▒░▒██  ▀█▄  ▓██  ▀█ ██▒▒ ▓██░ ▒░░ ▓██▄   ////////////////////////////////
///////////////////////////▓██▒  ▐▌██▒▒██   ██░░ ▓██▓ ░ ▒██   ██░▓██ █▄░██▄▄▄▄██  ░ ▐██▓░▒██    ▒██ ▓▓█  ░██░░ ▓██▓ ░ ░██▄▄▄▄██ ▓██▒  ▐▌██▒░ ▓██▓ ░   ▒   ██▒////////////////////////////////
///////////////////////////▒██░   ▓██░░ ████▓▒░  ▒██▒ ░ ░ ████▓▒░▒██▒ █▄▓█   ▓██▒ ░ ██▒▓░▒██▒   ░██▒▒▒█████▓   ▒██▒ ░  ▓█   ▓██▒▒██░   ▓██░  ▒██▒ ░ ▒██████▒▒////////////////////////////////
///////////////////////////░ ▒░   ▒ ▒ ░ ▒░▒░▒░   ▒ ░░   ░ ▒░▒░▒░ ▒ ▒▒ ▓▒▒▒   ▓▒█░  ██▒▒▒ ░ ▒░   ░  ░░▒▓▒ ▒ ▒   ▒ ░░    ▒▒   ▓▒█░░ ▒░   ▒ ▒   ▒ ░░   ▒ ▒▓▒ ▒ ░////////////////////////////////
///////////////////////////░ ░░   ░ ▒░  ░ ▒ ▒░     ░      ░ ▒ ▒░ ░ ░▒ ▒░ ▒   ▒▒ ░▓██ ░▒░ ░  ░      ░░░▒░ ░ ░     ░      ▒   ▒▒ ░░ ░░   ░ ▒░    ░    ░ ░▒  ░ ░////////////////////////////////
///////////////////////////   ░   ░ ░ ░ ░ ░ ▒    ░      ░ ░ ░ ▒  ░ ░░ ░  ░   ▒   ▒ ▒ ░░  ░      ░    ░░░ ░ ░   ░        ░   ▒      ░   ░ ░   ░      ░  ░  ░  ////////////////////////////////
///////////////////////////         ░     ░ ░               ░ ░  ░  ░        ░  ░░ ░            ░      ░                    ░  ░         ░                ░  ////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                      ░ ░                                                                         
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract NotOkayMutants is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.005 ether;

    string private BASE_URI = '';

    constructor() ERC721A("NotOkayMutants", "NOM") {
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

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount < 101, "Invalid mint amount!");
        require(currentIndex + _mintAmount < 5000, "Max supply exceeded!");
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
    0xcE2997F530e3f9F721FA1E4dAD248229466fbDE0;

    function thisisnotokay() public onlyOwner nonReentrant {
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