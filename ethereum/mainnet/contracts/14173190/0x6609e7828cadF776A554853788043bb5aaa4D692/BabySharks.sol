//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";



contract Deployed {
	function walletOfOwner(address _owner) public view returns (uint256[] memory){}
    function ownerOf(uint256 tokenId) public view returns (address) {}
}

contract SussyBabySharks is ERC721, ERC721Enumerable, Ownable {	
	
	Deployed dc;
	
	uint public constant MAX_TOKENS = 2000;
	uint public constant MAX_TOKENS_CLAIMABLE = 500;
	
	uint private _currentToken = 0;
	uint public currentClaimed = 0;
	
	
	
	//---- Round based supplies
	uint public CURR_MINT_COST = 0.06 ether;
	string private CURR_ROUND_NAME = "Public";
	string private CURR_ROUND_PASSWORD = "0";
	uint private CURR_ROUND_SUPPLY = 1500;
	uint private CURR_ROUND_TIME = 1645377373000;
	uint private maxMintAmount = 5;
	uint private nftPerAddressLimit = 15;
	
	
	bool public hasSaleStarted = false;
	
	string public baseURI;
	
    mapping(uint => bool) private claimed;
	
    uint256 private remaining = MAX_TOKENS;
    mapping(uint256 => uint256) private cache;
	
	constructor() ERC721("Sussy Baby Sharks", "BSHA") {
		setBaseURI("http://api.sussysharks.io/sussybabysharks/");
		dc = Deployed(0xa1CF519debbf6300992A9f7f76c85011d2373744);
	}
	
	function getParentItems(address _owner) public view returns (uint256[] memory)
    {
        return dc.walletOfOwner(_owner);
    }
	function getClaimable(address _owner) public view returns (uint256[] memory)
	{
        uint256[] memory tokens = dc.walletOfOwner(_owner);
        uint[] memory claimable = new uint[](tokens.length);
        for(uint x = 0; x< tokens.length;x++)
        {
            if(claimed[tokens[x]] == false)
			{
				claimable[x] = tokens[x];
			}
                
        }
		return claimable;
	}
	
	function tokenClaimable(uint tokenId) public view returns (bool)
	{
		if(claimed[tokenId] == false)
            return true;
        else
            return false;
	}

    function getParentOwner(uint tokenId) public view returns(address)
    {
        return dc.ownerOf(tokenId);
    }

    function claimBabyShark(uint token1, uint token2) public
    {
        require(claimed[token1] == false && claimed[token2] == false, "One or more tokens are already claimed");
        require(dc.ownerOf(token1) == msg.sender && dc.ownerOf(token2) == msg.sender, "You are not the owner of these tokens");
        require(currentClaimed <= MAX_TOKENS_CLAIMABLE,"Claim limit exchausted");
        require(token1 != token2, "Mismatch");
        claimed[token1] = true;
        claimed[token2] = true;
        

        uint theToken = drawIndex();
		_currentToken++;
        _safeMint(msg.sender, theToken);

        currentClaimed = currentClaimed + 1;

    }
	
	function totalSupply() public view override returns(uint) {
		return _currentToken;
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
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
	
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
	
    function drawIndex() private returns (uint256) {
        uint256 i = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, remaining))) % remaining;

        uint index = cache[i] == 0 ? i : cache[i];
		index = index == 0 ? MAX_TOKENS : index;
		
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        remaining = remaining - 1;
		
		return index;

    }

	function mintNFT(uint _mintAmount) public payable {
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
		require((_mintAmount  + balanceOf(msg.sender)) <= nftPerAddressLimit, "Max NFT per address exceeded");

		for (uint256 i = 1; i <= _mintAmount; i++) {
			_currentToken++;
			CURR_ROUND_SUPPLY--;
			uint theToken = drawIndex();
			_safeMint(msg.sender, theToken);
		}

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
	

	function setParentContract(address _parent) public onlyOwner
	{
		dc = Deployed(_parent);
	}

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

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require((_currentToken + numTokens) <= MAX_TOKENS, "Exceeded supply");
		uint index;
		// Reserved for the people who helped build this project
		for(index = 1; index <= numTokens; index++) {
			_currentToken++;
			uint theToken = drawIndex();
			_safeMint(recipient, theToken);
		}
	}

	function withdraw(uint amount) public payable onlyOwner {
		require(payable(msg.sender).send(amount));
	}
	
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}