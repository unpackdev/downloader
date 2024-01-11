// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract BasedWalrusCollective is ERC721, Ownable {

	using ECDSA for bytes32;
	using Strings for uint;
    
    uint constant MAX_BWC = 3333;
    uint constant maxPurchase = 10;
    uint constant maxPerWallet = 20;
	
	uint public totalSupply;
    uint8 public saleStatus = 0;
    
	mapping(address => uint) public addressMintedAmount;
	
    string private baseURI;
	string private baseExtension = ".json";	
	
	modifier overallSupplyCheck() {
		
        require(totalSupply < MAX_BWC, "All NFTs have been minted");
        _;
    }

    constructor() ERC721("Based Walrus Collective", "BWC") {}
	
	function remainingNFTs() private view returns (string memory) {
		
        return string(abi.encodePacked("There are only ", (MAX_BWC - totalSupply).toString(), " NFTs left in supply"));
    }
	
	function tokenURI(uint tokenId) public view virtual override returns (string memory) {
		
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function mint(uint amount) external payable overallSupplyCheck {
		
		require(saleStatus == 1, "Sale is not active");
		require(amount > 0 && amount <= maxPurchase, "Must mint between 1 and 10 NFTs");
		require(addressMintedAmount[msg.sender] + amount <= maxPerWallet, "Maximum 20 NFTs per wallet");

        mintBWC(amount);
    }

    function mintBWC(uint mintAmount) internal {
        
        require(totalSupply + mintAmount <= MAX_BWC, remainingNFTs());
        
		uint currSupply = totalSupply;
		
		totalSupply += mintAmount;
		
        for (uint i = 1; i <= mintAmount; i++) {
            addressMintedAmount[msg.sender]++;
            _safeMint(msg.sender, currSupply + i);
        }
    }
	
	// onlyOwner
    function setBaseURI(string memory newBaseURI) public onlyOwner {
		
        baseURI = newBaseURI;
    }
	
	function setSaleStatus(uint8 status) external onlyOwner {
		
		require(status == 0 || status == 1, "Invalid sale status");		
        saleStatus = status;
    }
}