//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract IAFL is ERC721, Ownable {
	using Counters
	for Counters.Counter;
	Counters.Counter private _tokenIds;
	
	
	uint public constant MAX_TOKENS = 8000;
	uint public constant MAX_TOKENS_VIP = 0;
	
	
	uint public CURR_MINT_COST = 0.08 ether;
	
	//---- Round based supplies
	string public CURR_ROUND_NAME = "Public";
	string public CURR_ROUND_PASSWORD = "0";
	uint public CURR_ROUND_SUPPLY = 8000;
	uint public CURR_ROUND_TIME = 1641492000000;
	
	uint public maxMintAmount = 20;
	uint public nftPerAddressLimit = 100;
	uint public currentVIPs = 0;
	uint public currentNormal = 0;
	
	bool public hasSaleStarted = false;
	
	string public baseURI;
	
	mapping(address => uint) public addressMintedBalance;

    uint256 internal remaining = MAX_TOKENS;
    mapping(uint256 => uint256) internal cache;
	
	constructor() ERC721("Its a Fungible Life", "IAFL") {
		setBaseURI("http://api.itsafungiblelife.com/afungiblelife/");
	}

	function totalSupply() public view returns(uint) {
		return currentNormal;
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}


    function drawIndex() internal returns (uint256 index) {
        uint256 i = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, remaining, CURR_ROUND_SUPPLY))) % remaining;

        index = cache[i] == 0 ? i : cache[i];

        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        remaining = remaining - 1;

    }




	function mintNFT(uint _mintAmount) public payable {
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");

		for (uint256 i = 1; i <= _mintAmount; i++) {
			addressMintedBalance[msg.sender]++;
			_tokenIds.increment();
			CURR_ROUND_SUPPLY--;
			currentNormal = currentNormal + 1;
			uint theToken = drawIndex();
			_safeMint(msg.sender, theToken);
		}
	}


   function getInformations() public view returns (string memory)
   {
	   string memory information = string(abi.encodePacked(CURR_ROUND_NAME,",", Strings.toString(CURR_ROUND_SUPPLY),",",Strings.toString(CURR_ROUND_TIME),",",Strings.toString(CURR_MINT_COST),",",Strings.toString(maxMintAmount), ",",CURR_ROUND_PASSWORD));
	   return information;
   }
	
	
	//only owner functions
	
	function setNewRound(uint _supply, uint cost, string memory name, uint maxMint, uint perAddressLimit, uint theTime, string memory password) public onlyOwner {
		require(_supply <= MAX_TOKENS - totalSupply(), "Exceeded supply");
		CURR_ROUND_SUPPLY = _supply;
		CURR_MINT_COST = cost;
		CURR_ROUND_NAME = name;
		maxMintAmount = maxMint;
		nftPerAddressLimit = perAddressLimit;
		CURR_ROUND_TIME = theTime;
		CURR_ROUND_PASSWORD = password;
	}
	
	function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
		nftPerAddressLimit = _limit;
	}

	function setmaxMintAmount(uint _newmaxMintAmount) public onlyOwner {
		maxMintAmount = _newmaxMintAmount;
	}

	function setCurrentSupply(uint numSupply) public onlyOwner{
		require(numSupply<=MAX_TOKENS - totalSupply(), "Can't add new character NFTs. Would exceed supply");
		CURR_ROUND_SUPPLY = numSupply;
	}

	function setCost(uint _newCost) public onlyOwner {
		CURR_MINT_COST = _newCost;
	}



	function setBaseURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	function getBaseURI() public onlyOwner view returns(string memory) {
		return baseURI;
	}

	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require((_tokenIds.current() + numTokens) <= MAX_TOKENS, "Exceeded supply");
		uint index;
		// Reserved for the people who helped build this project
		for(index = 1; index <= numTokens; index++) {
			_tokenIds.increment();
			currentNormal = currentNormal + 1;
			
			addressMintedBalance[recipient]++;
			uint theToken = drawIndex();
			_safeMint(recipient, theToken);
		}
	}

	function withdrawAll() public payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}
	
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}