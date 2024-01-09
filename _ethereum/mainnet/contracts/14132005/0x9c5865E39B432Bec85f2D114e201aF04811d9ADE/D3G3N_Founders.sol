// SPDX-License-Identifier: GPL-3.0
// Authored by NoahN w/ Metavate ✌️
pragma solidity ^0.8.11;
import "./Strings.sol";
import "./ERC721.sol";

contract D3g3nFoundersToken is ERC721{ 
  	using Strings for uint256;

    uint256 public cost = 0.0333 ether;
    uint256 private mintCount = 0;
    uint256 private maxSupply = 333;

    bool public sale = false;

	string public baseURI;
	
    mapping (address => uint256) public purchased ;

    address private owner;
	address private admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
    
	constructor(string memory _name, string memory _symbol) 
	ERC721(_name, _symbol){
	    owner = msg.sender;
    }

	modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin, "Not team" );
        _;
    }

    function mint() public payable{
        require(sale, "Sale");
		require(purchased[msg.sender] < 2, "Max purchased");
        require(cost == msg.value, "ETH value");
    	require(mintCount + 1 <= maxSupply, "Max supply");

		purchased[msg.sender] += 1;
        _safeMint(msg.sender, mintCount, "");
		mintCount += 1;
    }

	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyTeam{
    	require(quantity.length == recipient.length, "Matching lists" ); // Require quantity and recipient lists to be of the same length
    	uint totalQuantity = 0;
    	uint256 s = mintCount;
		// Sum the total amount of NFTs being gifted
    	for(uint i = 0; i < quantity.length; ++i){
    	    totalQuantity += quantity[i];
    	}
		require(mintCount + totalQuantity <= 333, "Max supply");
		mintCount += totalQuantity;
		delete totalQuantity;
    	for(uint i = 0; i < recipient.length; ++i){
        	for(uint j = 0; j < quantity[i]; ++j){
        	    _safeMint(recipient[i], s++, "" );
        	}
    	}
    	delete s;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    	require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    	string memory currentBaseURI = _baseURI();
    	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}

	function setBaseURI(string memory _newBaseURI) public onlyTeam {
	    baseURI = _newBaseURI;
	}
    
	function toggleSale() public onlyTeam {
	    sale = !sale;
	}

	function _baseURI() internal view virtual override returns (string memory) {
	    return baseURI;
	}

	function totalSupply() public view returns (uint256) {
        return mintCount;
    }

    function withdraw()  public onlyTeam {
        payable(admin).transfer(address(this).balance * 20 / 100);
        payable(owner).transfer(address(this).balance);
    }
}