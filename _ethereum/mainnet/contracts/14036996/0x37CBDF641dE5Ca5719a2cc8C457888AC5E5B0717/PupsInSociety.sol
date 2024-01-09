//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";


contract PupsInSociety is ERC721, Ownable {	
	
	uint public constant MAX_TOKENS = 10000;
	uint public constant MAX_TOKENS_VIP = 0;
	
	uint private _currentToken = 0;
	
	uint public CURR_MINT_COST = 0.1 ether;
	
	//---- Round based supplies
	string private CURR_ROUND_NAME = "Presale";
	string private CURR_ROUND_PASSWORD = "0";
	uint private CURR_ROUND_SUPPLY = 3600;
	uint private CURR_ROUND_TIME = 1643493600000;
	uint private maxMintAmount = 5;
	uint private nftPerAddressLimit = 10;
	
	uint private currentVIPs = 0;
	
	bool public hasSaleStarted = false;
	bool public onlyWhitelisted = false;
	
	string public baseURI;
	
	mapping(address => uint) public addressMintedBalance;
	mapping (address => bool) private whitelistUserAddresses;
	
    uint256 private remaining = MAX_TOKENS;
    mapping(uint256 => uint256) private cache;
	
	constructor() ERC721("Pups in Society", "PUPS") {
		setBaseURI("http://api.pupsinsociety.com/pups/");
	}

	function totalSupply() public view returns(uint) {
		return _currentToken;
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
	
	
    function drawIndex() private returns (uint256 index) {
        uint256 i = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, remaining))) % remaining;

        index = cache[i] == 0 ? i : cache[i];
		index = index == 0 ? MAX_TOKENS : index;
		
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        remaining = remaining - 1;

    }

	function mintNFT(uint _mintAmount) public payable {
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
		require((_mintAmount  + addressMintedBalance[msg.sender]) <= nftPerAddressLimit, "Max NFT per address exceeded");



        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "User is not whitelisted");
        }

		for (uint256 i = 1; i <= _mintAmount; i++) {
			addressMintedBalance[msg.sender]++;
			_currentToken++;
			CURR_ROUND_SUPPLY--;
			uint theToken = drawIndex();
			_safeMint(msg.sender, theToken);
		}

	}

	
	function isWhitelisted(address _user) public view returns (bool) {
		return whitelistUserAddresses[_user];
	}
	
	
   function getInformations() public view returns (string memory)
   {
	   string memory information = string(abi.encodePacked(CURR_ROUND_NAME,",", Strings.toString(CURR_ROUND_SUPPLY),",",Strings.toString(CURR_ROUND_TIME),",",Strings.toString(CURR_MINT_COST),",",Strings.toString(maxMintAmount), ",",CURR_ROUND_PASSWORD, ",",Strings.toString(nftPerAddressLimit)));
	   return information;
   }
	
	function getBaseURI() public onlyOwner view returns(string memory) {
		return baseURI;
	}
	
	//only owner functions
	
	function setNewRound(uint _supply, uint cost, string memory name, uint perTransactionLimit, uint perAddressLimit, uint theTime, string memory password, bool saleState) public onlyOwner {
		require(_supply <= (MAX_TOKENS - _currentToken), "Exceeded supply");
		CURR_ROUND_SUPPLY = _supply;
		CURR_MINT_COST = cost;
		CURR_ROUND_NAME = name;
		maxMintAmount = perTransactionLimit;
		nftPerAddressLimit = perAddressLimit;
		CURR_ROUND_TIME = theTime;
		CURR_ROUND_PASSWORD = password;
		hasSaleStarted = saleState;
	}

	
	function whitelistAddresses (address[] calldata users) public onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			whitelistUserAddresses[users[i]] = true;
		}
	}

	function removeWhitelistAddresses (address[] calldata users) external onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			delete whitelistUserAddresses[users[i]];
		}
	}
	
	function setOnlyWhitelisted(bool _state) public onlyOwner {
		onlyWhitelisted = _state;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function reserveVIP(uint numTokens, address recipient) public onlyOwner {
		require((currentVIPs + numTokens) <= MAX_TOKENS_VIP, "Exceeded VIP supply");
		uint index;
		for(index = 1; index <= numTokens; index++) {
			_currentToken++;
			currentVIPs = currentVIPs + 1;
			uint theToken = currentVIPs + MAX_TOKENS;
			addressMintedBalance[recipient]++;
			_safeMint(recipient, theToken);
		}
	}

	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require((_currentToken + numTokens) <= MAX_TOKENS, "Exceeded supply");
		uint index;
		// Reserved for the people who helped build this project
		for(index = 1; index <= numTokens; index++) {
			_currentToken++;
			uint theToken = drawIndex();
			addressMintedBalance[recipient]++;
			_safeMint(recipient, theToken);
		}
	}
	
	function smartContractBalance() public view returns(uint)
	{
		return address(this).balance;
	}

	function withdrawAll(uint amount) public payable onlyOwner {
		payable(msg.sender).send(amount);
	}
	
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}