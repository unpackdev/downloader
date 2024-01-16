// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

                                                                                                               
//88b           d88    ,ad8888ba,      ,ad8888ba,    888b      88  88      a8P   88  88888888ba,     ad88888ba   
//888b         d888   d8"'    `"8b    d8"'    `"8b   8888b     88  88    ,88'    88  88      `"8b   d8"     "8b  
//88`8b       d8'88  d8'        `8b  d8'        `8b  88 `8b    88  88  ,88"      88  88        `8b  Y8,          
//88 `8b     d8' 88  88          88  88          88  88  `8b   88  88,d88'       88  88         88  `Y8aaaaa,    
//88  `8b   d8'  88  88          88  88          88  88   `8b  88  8888"88,      88  88         88    `"""""8b,  
//88   `8b d8'   88  Y8,        ,8P  Y8,        ,8P  88    `8b 88  88P   Y8b     88  88         8P          `8b  
//88    `888'    88   Y8a.    .a8P    Y8a.    .a8P   88     `8888  88     "88,   88  88      .a8P   Y8a     a8P  
//88     `8'     88    `"Y8888Y"'      `"Y8888Y"'    88      `888  88       Y8b  88  88888888Y"'     "Y88888P"   
                                                                                                               
                                                                                                               

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";

contract Moonkids is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;
    
    uint256 public MAX_SUPPLY = 565;
    uint256 public MAX_FREE_SUPPLY = 0;
    uint256 public MAX_PER_TX = 10;
    string  public baseTokenURI = "";
    uint256 public PRICE = 0.002 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    bool public status = false;

    mapping(address => uint256) public perWalletFreeMinted;

    constructor() ERC721A("MoonKids", "MOONKIDS") {}


    function ownerMint(address to, uint amount) external onlyOwner {
		require(
			_totalMinted() + amount <= MAX_SUPPLY,
			'Exceeds max supply'
		);
		_safeMint(to, amount);
	}

    function publicmint(uint256 amount) external payable
    {
        
		require(amount <= MAX_PER_TX,"Exceeds NFT per transaction limit");
		require(_totalMinted() + amount <= MAX_SUPPLY,"Exceeds max supply");
        require(status, "Minting is not live yet.");
        uint payForCount = amount;
        uint minted = perWalletFreeMinted[msg.sender];
        if(minted < MAX_FREE_PER_WALLET && _totalMinted()<MAX_FREE_SUPPLY) {
            uint remainingFreeMints = MAX_FREE_PER_WALLET - minted;
            if(amount > remainingFreeMints) {
                payForCount = amount - remainingFreeMints;
            }
            else {
                payForCount = 0;
            }
        }

		require(
			msg.value >= payForCount * PRICE,
			'Ether value sent is not sufficient'
		);
    	perWalletFreeMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    
    function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : baseTokenURI;
	}

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }


    function setStatus(bool _status) external onlyOwner
    {
        status = _status;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_PER_WALLET = _limit;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner
    {
        MAX_FREE_SUPPLY = _amount;
    }

}