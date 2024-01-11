// SPDX-License-Identifier: MIT

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////██████╗ ██╗  ██╗███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██████╗ ██╗██████╗ ██████╗ ███████╗///////////////////////
///////////////////////////////██╔═████╗╚██╗██╔╝████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██╔══██╗██║██╔══██╗██╔══██╗██╔════╝//////////////////////
///////////////////////////////██║██╔██║ ╚███╔╝ ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██████╔╝██║██████╔╝██║  ██║███████╗//////////////////////
///////////////////////////////████╔╝██║ ██╔██╗ ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║██╔══██╗██║██╔══██╗██║  ██║╚════██║//////////////////////
///////////////////////////////╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝██║██║  ██║██████╔╝███████║///////////////////////
///////////////////////////////╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                           
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ZeroXMoonBirds is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.0069 ether;
    uint256 public MAX_SUPPLY = 6777;
    
    uint256 public MAX_MINT_FOR_TXN = 101;

    string private BASE_URI = '';

    bool public REVEAL_STATUS = false;

    constructor() ERC721A("ZeroXMoonBirds", "0xMB") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
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
        uint256 price = PRICE * _mintAmount;
        require(msg.value >= price, "Insufficient funds!");
        
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAdd =
    0x58D6b3153020ccBBc97e3A3c106DEbB02F50d7C0;

    function birdstothemoon() public onlyOwner nonReentrant {
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
            return 'https://gateway.pinata.cloud/ipfs/QmZfskPyGZZM3GtU6wqJLdxgtXCYWJa1jK2qQz25CSxQ6y';
        }
    }
}