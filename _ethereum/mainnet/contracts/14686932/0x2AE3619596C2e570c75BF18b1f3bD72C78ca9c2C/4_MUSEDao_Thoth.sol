// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

interface IWRLD_Token_Ethereum {
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
}

contract MUSEDao_Thoth is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable{

	IWRLD_Token_Ethereum public wrld;
	
	uint256 ethMintCost = 0.1 ether;
	uint256 wrldMintCost = 1888 ether;
	uint256 whitelistEthCost = 0.07 ether;
	uint256 whitelistWrldCost = 1111 ether;

	uint16 maxSupply = 800;
	uint8 maxMintAmount = 10;
	uint8 maxWhitelistMint = 5;

	string public baseURI;
	string public baseExtension = ".json";
	bool public whitelistPaused = true;
	address public payoutWallet;
	bytes32 public merkleRoot;

	mapping(address => uint8) public numWhitelistMints;

	constructor(address _wlrdAddress) ERC721("MUSEDao", "THTH"){
		wrld = IWRLD_Token_Ethereum(_wlrdAddress);
		_pause();
		mintInitial();
	}

	function mintInitial() private{
		address owner = owner();
		for(uint i = 0; i < 149; i++){
			_safeMint(owner, i + 1);
		}
	}

	function ethMint(uint8 _amount) external payable whenNotPaused nonReentrant{
		uint supply = totalSupply();
		require(_amount > 0, "Amount must be greater than 0");
		require(_amount <= maxMintAmount, "Mint amount must be less then or equal to 10");
		require(supply + _amount <= maxSupply, "Mint is sold out");
		require(msg.value >= _amount*ethMintCost, "Not enough ETH");

		for(uint i = 1;i <= _amount;i++){
			_safeMint(msg.sender, supply + i);
		}
	}

	function wrldMint(uint8 _amount) external payable whenNotPaused nonReentrant{
		uint256 supply = totalSupply();
		require(_amount > 0, "Amount must be greater than 0");
		require(_amount <= maxMintAmount, "Mint amount must be less then or equal to 10");
		require(supply + _amount <= maxSupply, "Mint is sold out");
		require(msg.value == 0, "Minting is done via WRLD");
		require(wrldMintCost * _amount <= wrld.balanceOf(msg.sender), "Not enough WRLD");
		require(wrldMintCost * _amount <= wrld.allowance(msg.sender, address(this)), "Not enough WRLD allowance");

		wrld.transferFrom(msg.sender, address(this), wrldMintCost * _amount);

		for(uint i = 1;i <= _amount;i++){
			_safeMint(msg.sender, supply + i);
		}
	}

	function whitelistEthMint(uint8 _amount, bytes32[] memory _proof) external payable nonReentrant{
		uint supply = totalSupply();
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(whitelistPaused == false, "Whitelist is paused");
		require(_amount <= maxWhitelistMint, "Mint amount must be less then or equal to 5");
		require(MerkleProof.verify(_proof, merkleRoot, leaf) == true, "Address not whitelisted");
		require(_amount + numWhitelistMints[msg.sender] <= maxWhitelistMint, "Max whitelist mints per address is 5");
		require(supply + _amount <= maxSupply, "Mint is sold out");
		require(msg.value >= _amount*whitelistEthCost, "Not enough ETH");

		numWhitelistMints[msg.sender] = numWhitelistMints[msg.sender] + _amount; 

		for(uint i = 1;i <= _amount;i++){
			_safeMint(msg.sender, supply + i);
		}
	}

	function whitelistWrldMint(uint8 _amount, bytes32[] memory _proof) external payable nonReentrant{
		uint supply = totalSupply();
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(whitelistPaused == false, "Whitelist is paused");
		require(_amount <= maxWhitelistMint, "Mint amount must be less then or equal to 5");
		require(MerkleProof.verify(_proof, merkleRoot, leaf) == true, "Address not whitelisted");
		require(_amount + numWhitelistMints[msg.sender] <= maxWhitelistMint, "Max whitelist mints per address is 5");
		require(supply + _amount <= maxSupply, "Mint is sold out");
		require(msg.value == 0, "Minting is done via WRLD");
		require(whitelistWrldCost * _amount <= wrld.balanceOf(msg.sender), "Not enough WRLD");
		require(whitelistWrldCost * _amount <= wrld.allowance(msg.sender, address(this)), "Not enough WRLD allowance");

		numWhitelistMints[msg.sender] = numWhitelistMints[msg.sender] + _amount; 
		wrld.transferFrom(msg.sender, address(this), whitelistWrldCost * _amount);

		for(uint i = 1;i <= _amount;i++){
			_safeMint(msg.sender, supply + i);
		}
	}

	function unpause() external onlyOwner{
		_unpause();
	}

	function pause() external onlyOwner{
		_pause();
	}

	function setWhitelistPause(bool _paused) external onlyOwner{
		whitelistPaused = _paused;
	}

	function setMerkleRoot(bytes32 _root) external onlyOwner{
		merkleRoot = _root;
	}

	function setPayoutWallet(address _wallet) external onlyOwner{
		payoutWallet = _wallet;
	}

	function withdraw() external payable onlyOwner{
		uint256 balance = wrld.balanceOf(address(this));
		wrld.approve(address(this), balance);
		payable(payoutWallet).transfer(address(this).balance);
		wrld.transferFrom(address(this), payoutWallet, balance);
	}

	function getWhiteListMintCount(address _address) external view returns(uint256){
		return numWhitelistMints[_address];
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
		require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0
			? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
			: "";
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner{
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _extension) public onlyOwner{
		baseExtension = _extension;
	}

	//Internal
	function _baseURI() internal view virtual override returns (string memory){
		return baseURI;
	}
}