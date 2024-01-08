// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;
import "./ERC721Enum.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract ZeviGMintPass is ERC721Enum{ 
	using Strings for uint256;
    using SafeMath for uint256;

	uint256 public cost = 1.5 ether;
	uint256 public maxSupply = 45;
    bool public sale = false;
	string public baseURI;
	address private owner;
	address private admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
	address private nftContract;
	mapping(uint256 => bool) public passUsed;
	mapping(address => uint256) public passesBought;
	constructor() ERC721P("456 Collector's Club Mint Pass","456PASS"){
	    owner = msg.sender;
	}
	
	
	 modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin || msg.sender == nftContract, "Not team" );
        _;
    }
    
	
	function mint(uint256 _mintAmount) public payable { 
    	require(sale, "Off" );
    	require(msg.value == cost * _mintAmount, "ETH value");
    	require(_mintAmount + passesBought[msg.sender] < 6); 
    	passesBought[msg.sender] += _mintAmount;
    	uint256 s = totalSupply();
    	require(_mintAmount + s <= maxSupply, "Max supply");
    	for (uint256 i = 0; i < _mintAmount; ++i) {
        	_safeMint(msg.sender, s + i, "");
    	}
    	delete s;
	}
	
	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyTeam{
    	require(quantity.length == recipient.length, "Matching lists" );
    	uint totalQuantity = 0;
    	uint256 s = totalSupply();
    	for(uint i = 0; i < quantity.length; ++i){
    	    totalQuantity += quantity[i];
    	}
    	require(totalQuantity + s <= maxSupply, "Max supply");
    	delete totalQuantity;
    	for(uint i = 0; i < recipient.length; ++i){
        	for(uint j = 0; j < quantity[i]; ++j){
        	    _safeMint( recipient[i], s++, "" );
        	}
    	}
    	delete s;
	}
	
	function setPassUsed(uint256 tokenId) external onlyTeam{
	    passUsed[tokenId] = true;
	}
	
	function getPassUse(uint256 passTokenId) external view returns(bool){
	    return passUsed[passTokenId];
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    	require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    	string memory currentBaseURI = _baseURI();
    	uint256 used = passUsed[tokenId]? 1:0;
    	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), "-", used.toString(), ".json")) : "";
	}
	
	function setCost(uint256 _newCost) public onlyTeam {
	    cost = _newCost;
	}
	
	function setmaxSupply(uint256 _newMaxSupply) public onlyTeam {
	    require(_newMaxSupply >= totalSupply(), "Too low");
	    maxSupply = _newMaxSupply;
	}
	
	function setBaseURI(string memory _newBaseURI) public onlyTeam {
	    baseURI = _newBaseURI;
	}
	
	function setNFTContract(address _nftContract) public onlyTeam {
	    nftContract = _nftContract;
	}
	
	function toggleSale() public onlyTeam {
	    sale = !sale;
	}
	
	function _baseURI() internal view virtual returns (string memory) {
	    return baseURI;
	}
	
    function withdraw()  public onlyTeam {
        payable(admin).transfer((address(this).balance * 7 / 100) + (address(this).balance * 5 / 1000) ); //send 7.5% to team member
        payable(owner).transfer(address(this).balance); //send balance to owner
    }
}