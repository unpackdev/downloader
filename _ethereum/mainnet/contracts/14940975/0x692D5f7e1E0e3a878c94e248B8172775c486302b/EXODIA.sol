//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Exodia is ERC721A, Ownable {

	uint public constant MAX_TOKENS = 2000;
	
	uint public CURR_MINT_COST = 0 ether;
	
	//---- Round based supplies
	string private CURR_ROUND_NAME = "Free Mint";
	uint private CURR_ROUND_SUPPLY = 400;
	uint private CURR_ROUND_TIME = 0;
	uint private maxMintAmount = 1;
	uint private nftPerAddressLimit = 1;

	bool public hasSaleStarted = false;
	
	string public baseURI;
	
	constructor() ERC721A("Exodia", "EXODIA") {
		setBaseURI("ipfs://QmUvF2BA4sr4Yf2XMus4ST4GKMJjQLyRDbrcg43ajN5iij/");
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,Strings.toString(_tokenId+1),".json"))
            : "";
    }

	function mintNFT(uint _mintAmount) external payable {
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
		require((_mintAmount  + balanceOf(msg.sender)) <= nftPerAddressLimit, "Max NFT per address exceeded");

		CURR_ROUND_SUPPLY -= _mintAmount;
		_safeMint(msg.sender, _mintAmount);
		
	}

	
	//only owner functions
	
	function setNewRound(uint _supply, uint cost, string memory name, uint perTransactionLimit, uint perAddressLimit, uint theTime, bool saleState) external onlyOwner {
		require(_supply <= (MAX_TOKENS - totalSupply()), "Exceeded supply");
		CURR_ROUND_SUPPLY = _supply;
		CURR_MINT_COST = cost;
		CURR_ROUND_NAME = name;
		maxMintAmount = perTransactionLimit;
		nftPerAddressLimit = perAddressLimit;
		CURR_ROUND_TIME = theTime;
		hasSaleStarted = saleState;
	}


	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require(numTokens <= CURR_ROUND_SUPPLY, "We're at max supply!");
		CURR_ROUND_SUPPLY -= numTokens;
		_safeMint(recipient, numTokens);
	}

	function withdraw(uint amount) public onlyOwner {
		require(payable(msg.sender).send(amount));
	}
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}