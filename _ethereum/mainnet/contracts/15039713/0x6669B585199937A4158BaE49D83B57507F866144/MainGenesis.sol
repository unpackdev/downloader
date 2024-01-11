// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ITemple.sol";
import "./IMyToken.sol";

contract MyGenesis is ERC721A, Ownable {
	// Set the minting rules: prices / quantities
	uint256 public MAX_NFT_PUBLIC		= 268;
	uint256 public NFTPrice			= 0.049 ether;
	uint256 public maxPerTransaction	= 2;

	// To pay dev support after the mint
	uint256 private devSup	= 2.2 ether;
	address private dev	= 0x3Fbf6Db5b6852633eF1ECFA369440e2EB42B4d12;

	// Boolean to activate the different Sales
	bool public isActive		= false;
	bool public isPresaleActive	= false;
	bool public isPublicSaleActive	= false;
	bool public isFreeMintActive	= false;

	// To set IPFS link
	mapping(uint => string) public baseURL;

	// Manage OG & WL NFT claimed & Giveaway
	uint256 count = 0;
	mapping(uint256 => mapping(address => uint256)) private whiteListClaimed;
	mapping(uint256 => mapping(address => bool)) private giveawayMintClaimed;

	// Link to the OG / WL & giveaway
	bytes32 public root;

	struct Genesis {
		bool isWear;		// an NFT is wearin it?
		uint256 lastTime;	// last time it has been worn?
		bool inTemple;      	// Is it staked in the Temple
	}

    	// Time delay between two times the Pass
	// has been weard
	uint256 private delay	= 518400;	// 6 days

    	// Map the token index to its Structure
	mapping(uint256 => Genesis) public nfts;

	// Link to MyNFT
	address private myNFT;
    	// Link to the temple service
	ITemple private Itemple;
    	// Link to MyToken contract
	IMyToken private myToken;

	// Deploy the contract
	constructor() ERC721A("Reincarnation Pass", "BBRP")
	{
		baseURL[0]	= "https://gateway.pinata.cloud/ipfs/Qmaj4vNgVHooTZHf3KE4jJaRdwAajbVa22xFVLAK2GQTyT/ReincarnationPass";
		safeMint(0x9Aac44cA96C37948b55587f8ee347A57400886e4, 1);
	}
	
	function resetList()
	external
	onlyOwner
	{
		count++;
	}
	
	function setSale(uint256 _price, uint256 max_, uint256 max_per_transaction, uint256 _root)
	external
	onlyOwner
	{
		(NFTPrice, MAX_NFT_PUBLIC,
		 maxPerTransaction, root)	= (_price, max_, max_per_transaction, bytes32(_root));
	}
	
	// Function toggleActive to activate/desactivate
	// the smart contract
	function toggleActive()
	external
	onlyOwner
	{
		isActive = !isActive;
	}

	// Function togglePublicSale
	// to activate/desactivate public sale
	function togglePublicSale()
	external
	onlyOwner
	{
		isPublicSaleActive = !isPublicSaleActive;
	}

	// Function togglePresale to activate/desactivate presale
	function togglePresale()
	external
	onlyOwner
	{
		isPresaleActive = !isPresaleActive;
	}

	//Function to activate/desactivate the free mint
	function toggleFreeMint()
	external
	onlyOwner
	{
		isFreeMintActive = !isFreeMintActive;
	}

	// Allow Mint
	function AllowMint(uint256 _numOfTokens, bool correctSale)
	private
	view
	{
		require(isActive, "Not Active");
		require(_numOfTokens <= maxPerTransaction, "Above Limit");
		require(totalSupply() + _numOfTokens <= MAX_NFT_PUBLIC, "Exceeds Supply");
		require(correctSale, "Wrong Sale");
	}
	
	// Check value to pay
	function isEnough(uint256 _numOfTokens, uint256 _value)
	private
	view
	{
		require(NFTPrice * _numOfTokens <= _value, "Not Enough Ether");
	}

	// Minting function which called the ERC721A safeMint function
	// to reduce the gas fee
	function safeMint(address _to, uint256 _quantity)
	internal
	{
		// Get current index
		uint256 currentIndex	= totalSupply();

		// Mint NFTs
		_safeMint(_to, _quantity);

		for (uint256 i = currentIndex; i < currentIndex + _quantity; i++)
			nfts[i]	= Genesis(false, 0, false);
	}

	//Function to mint all NFTs for giveaway
	function giveawayMint(address[] memory _to)
	external
	onlyOwner
	{
		for(uint i=0; i<_to.length; i++)
			safeMint(_to[i], 1); 
	}

	// Function to mint new NFTs during the public sale
	function mintNFT(uint256 _numOfTokens)
	external
	payable
	{
		AllowMint(_numOfTokens, !isPresaleActive);
		isEnough(_numOfTokens, msg.value);

		safeMint(msg.sender, _numOfTokens);
	}

	// Function to verify merkle proof
	function verify(bytes32[] memory proof, bytes32 leaf)
	private
	view
	returns (bool)
	{
		bytes32 computedHash = leaf;

		for (uint256 i = 0; i < proof.length; i++) {
			bytes32 proofElement = proof[i];

			if (computedHash <= proofElement)
				computedHash = sha256(abi.encodePacked(computedHash, proofElement));
			else
				computedHash = sha256(abi.encodePacked(proofElement, computedHash));
		}

		return computedHash == root;
	}

	// Function to mint new NFTs during the presale
	function mintNFTDuringPresale(uint256 _numOfTokens, bytes32[] memory _proof)
	external
	payable
	{
		AllowMint(_numOfTokens, isPresaleActive);
		require(verify(_proof, bytes32(uint256(uint160(msg.sender)))), "Not whitelisted");

		if (!isFreeMintActive){
			require(whiteListClaimed[count][msg.sender] + _numOfTokens <= maxPerTransaction, "Exceeds Max");
			isEnough(_numOfTokens, msg.value);
			whiteListClaimed[count][msg.sender] += _numOfTokens;
			safeMint(msg.sender, _numOfTokens);
		} else {
			require(_numOfTokens == 1, "Exceeds Max");
			require(!giveawayMintClaimed[count][msg.sender], "Already claimed");
			giveawayMintClaimed[count][msg.sender] = true;
			safeMint(msg.sender, _numOfTokens);
		}
	}

	// Allow the owner to transfer the fund at any address
	function withdraw(address _to)
	public
	onlyOwner
	{
		require(address(this).balance > 0, "Negative Balance");
		uint balance = address(this).balance;

		if(devSup > 0) {
			(bool sent, ) = dev.call{value: devSup}("");
			require(sent, "Failed to send Ether");
			balance = balance - devSup;
			devSup = 0;
		}

		(bool sent1, ) = _to.call{value: (balance * 990) / 1000}("");
		(bool sent2, ) = dev.call{value: (balance * 10) / 1000}("");
		require(sent1, "Failed to send Ether");
		require(sent2, "Failed to send Ether");
	}

	// Set the Golder Pass URL
	function setURL(string calldata url_, uint i_)
	external
	onlyOwner
	{
		baseURL[i_]	= url_;
	}

	// Set MyNFT address
	function setNFT(address _nft)
	external
	onlyOwner
	{
		myNFT	= _nft;
	}

	// Set Temple methods address
	function setTemple(address _temple)
	external
	onlyOwner
	{
		Itemple   = ITemple(_temple);
	}

	// Set Temple methods address
	function setToken(address _token)
	external
	onlyOwner
	{
		myToken   = IMyToken(_token);
	}

	function onlyNFTOwner(uint256 id, address from)
	private
	view
	{
		require(ownerOf(id) == from, "Not the NFT owner!");
	}

	function NFTinTemple(uint256 id, bool checkin)
	private
	view
	{
		require(nfts[id].inTemple == checkin, "Temple error");
	}
	
	function NFTisWear(uint256 id, bool check)
	private
	view
	{
		require(nfts[id].isWear == check, "Error with 'worn'");
	}

	function checkRequirements(uint256 id, address from, bool checkin)
	private
	view
	{
		onlyNFTOwner(id, from);
		NFTinTemple(id, checkin);
	}
	
	function checkIfStakeIsState()
	private
	view
	{
		require(address(Itemple) != address(0) && address(myToken) != address(0), "Not Yet Set!");
	}

	// Stake the NFT in the temple to earn MyTokens
	function stake(uint256 id)
	external
	{
		checkIfStakeIsState();
		checkRequirements(id, msg.sender, false);
		NFTisWear(id, false);

		nfts[id].inTemple   = Itemple.stake(id);
	}

	// Get Claimable From the Temple
	function claimBatch(uint256[] calldata ids)
	external
	{
		checkIfStakeIsState();
		
		uint256 toClaim	= 0;
		for (uint i=0; i<ids.length; i++)
		{
			Itemple.updateClaimable(ids[i]);
			toClaim	+= Itemple.claim(ids[i]);
		}
		
		// Add toClaim to the rewards already claimable
		myToken.addReward(ownerOf(ids[0]), toClaim);
	}

	// Push your NFT to be in a retreat
	function getInRetreat(uint256 id)
	external
	{
		checkRequirements(id, msg.sender, true);
		NFTisWear(id, false);

		// Get the current NFTs level
		Itemple.updateClaimable(id);

		Itemple.getInRetreat(id);
	}

	// Unstake the NFT from the Temple
	function _unstake(uint256 id)
	private
	returns(uint256)
	{
		// Get the current NFTs level
		Itemple.updateClaimable(id);

		// Update NFT features
		nfts[id].inTemple	= false;

		// Claim MyTokens and Unstake MyNFT
		return Itemple.unstake(id, nfts[id].isWear);
	}

	function wear(address from, uint256 id, bool toWear)
	external
	{
		require(msg.sender == myNFT && myNFT != address(0), "Wrong sender");
		onlyNFTOwner(id, from);
		NFTisWear(id, !toWear);
		
		if (toWear)
			require(nfts[id].lastTime + delay <= block.timestamp, "Need to Wait");
		
		nfts[id].isWear = toWear;
		if(nfts[id].inTemple && toWear)
			myToken.addReward(ownerOf(id), _unstake(id));
		
		if (!toWear)
			nfts[id].lastTime	= block.timestamp;
	}

	function unstake(uint256 id)
	external
	{
		checkRequirements(id, msg.sender, true);

		// Add toClaim to the rewards already claimable
		myToken.addReward(ownerOf(id), _unstake(id));
	}

	// Override transfer to verify not wear or not in the temple
	function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
	internal
	virtual
	override
	{
		for (uint i=startTokenId; i <= startTokenId+quantity; i++)
			require(!nfts[i].isWear && !nfts[i].inTemple, "Can't be transfered");
	}

	function tokenURI(uint256 tokenId)
	public
	view
	virtual
	override
	returns (string memory)
	{
		require(tokenId <= totalSupply(), "Wrong NFT Id!");
		if (tokenId >= 268)
			return string.concat(baseURL[1], Strings.toString(tokenId-268), ".json");
		
		return string.concat(baseURL[0], Strings.toString(tokenId), ".json");
	}
}
