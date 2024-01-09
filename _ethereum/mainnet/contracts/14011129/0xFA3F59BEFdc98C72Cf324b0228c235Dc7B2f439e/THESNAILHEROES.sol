// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract THESNAILHEROES is ERC721, Ownable {
    
    using Strings for uint256;
    
    bool public isSale = false;
    bool public preSale = false;

    uint256 public currentToken = 0;
    uint256 public maxSupply = 3333;
    uint256 public presalemaxSupply = 500;
    uint256 public price = 0.025 ether;
    string public metaUri = "https://thesnailheroes.com/tokens/";
    bool public isGiveawayactive = false;
    mapping (address => bool) public unclockedaddr;




    constructor() ERC721("The Snail Heroes", "SnailHEROESNFT") {
    
    }
    
    
    function get(address _addr) public view returns (bool) {
        // Mapping always returns a value.
        // If the value was never set, it will return the default value.
        return unclockedaddr[_addr];
    }

    function set(address _addr) public payable {

        require(0.008 ether <= msg.value, "Ether Amount Sent Is Incorrect");
        // Update the value at this address
        unclockedaddr[_addr] = true;
    }

      function setowner(address _addr) public onlyOwner {
        // Update the value at this address
        unclockedaddr[_addr] = true;
    }

    function remove(address _addr) public {
        // Reset the value to the default value.
        delete unclockedaddr[_addr];
    }

    // Mint Functions

    function mint(uint256 quantity) public payable {
        require(isSale==true, "Public Sale is Not Active");
        require((currentToken + quantity) <= maxSupply, "Quantity Exceeds Tokens Available");
        require((price * quantity) <= msg.value, "Ether Amount Sent Is Incorrect");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, currentToken);
            currentToken = currentToken + 1;
        }
    }


    function premint(uint256 quantity) public payable {
        require(preSale==true, "Pre Sale is Not Active");
        require((currentToken + quantity) <= presalemaxSupply, "Quantity Exceeds Tokens Available");
        require((price * quantity) <= msg.value, "Ether Amount Sent Is Incorrect");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, currentToken);
            currentToken = currentToken + 1;
        }
    }

    // Owner Mint Functions


    function ownerMint(address[] memory addresses) external onlyOwner {
        require((currentToken + addresses.length) <= maxSupply, "Quantity Exceeds Tokens Available");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], currentToken);
            currentToken = currentToken + 1;
        }
    }

     // Giveaway Mint Functions


    function GiveawayMint(address addresses) external payable {
        require (get(addresses)==true, "Please unlock yourself for giveaway");
        require(isGiveawayactive==true, "Giveaway Sale is Not Active");
        require((currentToken + 1) <= maxSupply, "Quantity Exceeds Tokens Available");
    {
            _safeMint(addresses, currentToken);
            currentToken = currentToken + 1;

        }
    }


    // Token URL and Supply Functions - Public

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString()));
    }
    
    function totalSupply() external view returns (uint256) {
        return currentToken;
    }
    
    // Setter Functions - onlyOwner

    function triggerSale() public onlyOwner {
        isSale = !isSale;
    }

     function triggerGiveawaySale() public onlyOwner {
        isGiveawayactive = !isGiveawayactive;
    }

    function triggerpreSale() public onlyOwner {
        preSale = !preSale;
    }




    function setMetaURI(string memory newURI) external onlyOwner {
        metaUri = newURI;
    }

    function setsupply(uint256 maxxsupply) external onlyOwner {
        maxSupply = maxxsupply;
    }

    // Withdraw Function - onlyOwner

    function withdraw() external onlyOwner {
        require(payable(0x0ECbE30790B6a690D4088B70dCC27664ca530D55).send(address(this).balance));
    }

    // Internal Functions

    function _baseURI() override internal view returns (string memory) {
        return metaUri;
    }
    
}