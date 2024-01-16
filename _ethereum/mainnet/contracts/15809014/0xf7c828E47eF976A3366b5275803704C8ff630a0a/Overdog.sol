// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// #######  ##     ## ######## ########  ########   #######   ######   
//##     ## ##     ## ##       ##     ## ##     ## ##     ## ##    ##  
//##     ## ##     ## ##       ##     ## ##     ## ##     ## ##        
//##     ## ##     ## ######   ########  ##     ## ##     ## ##   #### 
//##     ##  ##   ##  ##       ##   ##   ##     ## ##     ## ##    ##  
//##     ##   ## ##   ##       ##    ##  ##     ## ##     ## ##    ##  
// #######     ###    ######## ##     ## ########   #######   ######   


import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";

contract Overdog is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    // WhiteLists for presale.
    mapping (address => uint) public _numberOfPresale;
    mapping (uint => uint) public _numberOfAction;
    mapping (uint => uint) public _timeOfLastAction;
    uint256 public ETH_PRICE = 5000000000000000; // 0.005 ETH

    // Controlled variables
    uint256 private claimCountTracker;
    mapping(uint256 => uint256) public tokenIdToClaimId;
    mapping(uint256 => address) public tokenIdToClaimant;
    mapping(address => uint256[]) public claimantToTokenIds;
    
    uint256 public MAX_SUPPLY = 1000;
    string  public baseTokenURI = "";
    bool public status = false;
    bool public overlist = false;

    event claimedAgainstTokenId(address indexed claimant, uint256 indexed tokenId, uint256 timestamp);

    // Config variables
    ERC721 qualifyingToken;

    constructor(
        address _qualifyingTokenAddress
    ) 
    ERC721A("Overdog", "Overdog") {
        qualifyingToken = ERC721(_qualifyingTokenAddress);
    }

    function ownerMint(address to, uint amount) external onlyOwner {
		require(
			_totalMinted() + amount <= MAX_SUPPLY,
			'Exceeds max supply'
		);
		_safeMint(to, amount);
	  }

    function Overlist() public {
        require(overlist, "Whitelist is not live yet");
        require(_totalMinted()+ _numberOfPresale[msg.sender] <= MAX_SUPPLY, "Claim would exceed max supply of tokens");
        require(_numberOfPresale[msg.sender] > 0, "Overdog claim not allow");

        uint mintIndex = _numberOfPresale[msg.sender];
        if (_totalMinted() + mintIndex < MAX_SUPPLY) {
            _safeMint(msg.sender, mintIndex);
        }
        
        _numberOfPresale[msg.sender] = 0;
    }

    function addWhiteList(address[] calldata _wallet, uint8 _count) external onlyOwner {
        for (uint256 i = 0; i < _wallet.length; i++) {
            _numberOfPresale[_wallet[i]] = _count;
        }
    }

    function getPresaleCount(address wallet) public view returns(uint) {
        return _numberOfPresale[wallet];
    }

    function mintWithEthToken(uint amount) public payable {
        require(status, "Public Sales is not live yet");
        require(_totalMinted() + amount <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(ETH_PRICE * amount <= msg.value, "You dont have enough Ether");

        if (_totalMinted() + amount < MAX_SUPPLY) {
            _safeMint(msg.sender, amount);
        }
    }

    function claimAgainstTokenIds(uint256[] memory _tokenIds) public {
        require(_tokenIds.length > 0  && _tokenIds.length % 1 == 0, "Please provide Moonkid ID");
        uint32 pairs = uint32(_tokenIds.length / 1);
        //require(_tokenIds.length > 0, "ClaimAgainstERC721::claimAgainstTokenIds: no token IDs provided");
        require(overlist, "Claim is not live yet.");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenIdToClaimant[tokenId] == address(0), "Token with provided ID has already been claimed against");
            require(qualifyingToken.ownerOf(tokenId) == msg.sender, "Sender does not own specified token");
            tokenIdToClaimant[tokenId] = msg.sender;
            claimantToTokenIds[msg.sender].push(tokenId);
            emit claimedAgainstTokenId(msg.sender, tokenId, block.timestamp);
            // Do anything else that needs to happen for each tokenId here
        }
        claimCountTracker += _tokenIds.length;
        // Do anything else that needs to happen once per collection of claim(s) here
        _safeMint(msg.sender, pairs);
    }

    function claimCount() public view returns(uint256) {
        return claimCountTracker;
    }

    function claimantClaimCount(address _claimant) public view returns(uint256) {
        return claimantToTokenIds[_claimant].length;
    }

    function claimantToClaimedTokenIds(address _claimant) public view returns(uint256[] memory) {
        return claimantToTokenIds[_claimant];
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    
    function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : baseTokenURI;
	}

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    // Update ETH Price
    function setEthPrice(uint _newPrice) external onlyOwner {
        ETH_PRICE = _newPrice;
    }

    function setStatus(bool _status) external onlyOwner
    {
        status = _status;
    }

    function setOverlist(bool _overlist) external onlyOwner
    {
        overlist = _overlist;
    }

}