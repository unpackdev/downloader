//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract LegoX is ERC721, ERC721Enumerable, Ownable {

	uint private _tokenIds;

	uint private constant MAX_TOKENS_NORMAL = 9500;
	uint private constant MAX_TOKENS_RARE = 500;
	uint private constant MAX_TOKENS_VIP = 127;

	uint private constant MAX_TOKENS = MAX_TOKENS_NORMAL + MAX_TOKENS_RARE + MAX_TOKENS_VIP;

	uint private CURR_MINT_COST = 0.05 ether;
	
	//---- Round based supplies
	string private CURR_ROUND_NAME = "Presale-1";
	string private CURR_ROUND_PASSWORD = "e26ada5e6b6cc52ddcc99672ab8d1546";
	uint private CURR_ROUND_SUPPLY = 400;
	uint private CURR_ROUND_TIME = 1645210800000;
	
	uint public maxMintAmount = 3;
	uint public nftPerAddressLimit = 15;
	
	uint private currentNormalTokens = 0;
	uint private currentRareTokens = 0;
	uint private currentVIPs = 0;
	
	bool public hasSaleStarted = false;
	
	string public baseURI;
	
	mapping(address => uint) public addressMintedBalance;
	mapping(uint => uint) public nftAuctions;
	mapping(uint => bool) public vipsClaimed;
	
	constructor() ERC721("LegoX", "LegoX") {
		setBaseURI("http://api.legox.xyz/lego/");
	}

	function totalSupply() public view override returns(uint) {
		return _tokenIds;
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
	

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

	
	

	function walletOfOwner(address _owner) public view returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}

	function burnAndMint(uint tokenId1, uint tokenId2) public returns (uint) {
		require(msg.sender == ownerOf(tokenId1) && msg.sender == ownerOf(tokenId2),"You are not the token owner, try again");
		require(_exists(tokenId1) && _exists(tokenId2),"One or more tokens does not exist");
		require((currentRareTokens + 1) <= MAX_TOKENS_RARE, "No rare token supply available");
		currentRareTokens = currentRareTokens + 1;
		
		addressMintedBalance[msg.sender]--;
		
		_burn(tokenId1);
		_burn(tokenId2);
		_tokenIds--;

		uint theToken = MAX_TOKENS_NORMAL + currentRareTokens;
		_safeMint(msg.sender, theToken);
		return theToken;
	}

	function mintNFT(uint _mintAmount) public payable {
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
		uint256 ownerMintedCount = addressMintedBalance[msg.sender];
		require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT per address exceeded");
	
		
		for (uint256 i = 1; i <= _mintAmount; i++) {
		  addressMintedBalance[msg.sender]++;
		  _tokenIds++;
		  currentNormalTokens++;
		  CURR_ROUND_SUPPLY--;
		  _safeMint(msg.sender, currentNormalTokens);
		}

	}


	function getCurrentAuctions() public view returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(owner());
		uint256[] memory tokenIds = new uint256[](ownerTokenCount*2);
		uint count = 0;
		for (uint256 i; i < ownerTokenCount*2; i = i + 2) {
			tokenIds[i] = tokenOfOwnerByIndex(owner(), count);
			tokenIds[i + 1] = nftAuctions[tokenIds[i]];
			count++;
		}
		return tokenIds;
	}
	
   function getInformations() public view returns (string memory)
   {
	   string memory information = string(abi.encodePacked(CURR_ROUND_NAME,",", Strings.toString(CURR_ROUND_SUPPLY),",",Strings.toString(CURR_ROUND_TIME),",",Strings.toString(CURR_MINT_COST),",",Strings.toString(maxMintAmount), ",",CURR_ROUND_PASSWORD));
	   return information;
   }
	
	
	function findNextVip() public view returns (uint)
	{
		uint foundVip = 0;
		for(uint index = MAX_TOKENS_NORMAL + MAX_TOKENS_RARE + 1; index <= MAX_TOKENS_NORMAL + MAX_TOKENS_RARE + MAX_TOKENS_VIP; index++)
		{
			if(!vipsClaimed[index])
			{
				foundVip = index;
				break;
			}
		}

		return foundVip;

	}

	//only owner functions
	
	function setNewRound(uint _supply, uint cost, string memory name, uint maxMint, uint perAddressLimit, uint theTime, string memory password, bool saleState) public onlyOwner {
		require(_supply <= MAX_TOKENS_NORMAL, "Exceeded supply");
		CURR_ROUND_SUPPLY = _supply;
		CURR_MINT_COST = cost;
		CURR_ROUND_NAME = name;
		maxMintAmount = maxMint;
		nftPerAddressLimit = perAddressLimit;
		CURR_ROUND_TIME = theTime;
		CURR_ROUND_PASSWORD = password;
		hasSaleStarted = saleState;
	}

	function setCurrentSupply(uint numSupply) public onlyOwner{
		require(numSupply<=MAX_TOKENS_NORMAL, "Exceeded supply");
		CURR_ROUND_SUPPLY = numSupply;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function getBaseURI() public onlyOwner view returns(string memory) {
		return baseURI;
	}

	function mintAuctionNFT(uint numTokens, uint nftCost) public onlyOwner {
		require((currentVIPs + numTokens) <= MAX_TOKENS_VIP, "Exceeded VIP supply");
		uint index;
		for(index = 1; index <= numTokens; index++) {
			_tokenIds++;
			currentVIPs++;
			uint theToken = findNextVip();
			vipsClaimed[theToken] = true;

			nftAuctions[theToken] = nftCost;
			_safeMint(owner(), theToken);
		}
	}
	
	function buyAuctionNFT(uint tokenId) external payable returns(bool) {
		require(msg.value >= nftAuctions[tokenId], "Wrong cost paid for the NFT");
		require(balanceOf(msg.sender) > 0, "You should hold atleast 1 NFT to purchase auctions");
		require(nftAuctions[tokenId] >= 0, "This is not an auction item");
		require(owner() == ownerOf(tokenId), "Not an auction item");
		
		_transfer(owner(), msg.sender, tokenId);
		addressMintedBalance[msg.sender]++;
		return true;
	}

	function reserveVIP(uint numTokens, address recipient) public onlyOwner {
		require((currentVIPs + numTokens) <= MAX_TOKENS_VIP, "Exceeded VIP supply");
		uint index;
		for(index = 1; index <= numTokens; index++) {
			_tokenIds++;
			currentVIPs++;
			uint theToken = findNextVip();
			vipsClaimed[theToken] = true;
			addressMintedBalance[recipient]++;
			_safeMint(recipient, theToken);
		}
	}

	function reserveSpecificVIP(uint vipIndex, address recipient) public onlyOwner{
		require(findNextVip() > 0,"No vips left");
		require(vipsClaimed[vipIndex] == false,"This VIP is already reserved");
		require(vipIndex <= MAX_TOKENS_NORMAL + MAX_TOKENS_RARE + MAX_TOKENS_VIP,"Sequence higher than max supply");
		require(vipIndex > MAX_TOKENS_NORMAL + MAX_TOKENS_RARE,"Sequence lower than max vip supply");

		vipsClaimed[vipIndex] = true;

		currentVIPs++;
		_tokenIds++;
		addressMintedBalance[recipient]++;
		_safeMint(recipient, vipIndex);
	}



	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require((currentNormalTokens + numTokens) <= MAX_TOKENS_NORMAL, "Exceeded supply");
		uint index;

		for(index = 1; index <= numTokens; index++) {
			_tokenIds++;
			addressMintedBalance[recipient]++;
			currentNormalTokens++;
			_safeMint(recipient, currentNormalTokens);
		}
	}


	function withdrawAll(uint amount) public payable onlyOwner {
		require(payable(msg.sender).send(amount));
	}
	
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}