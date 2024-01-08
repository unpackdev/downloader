// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "imports.sol";

/* Bonus token for holders of any PAC DAO NFT */
contract PACDaoBonus1 is ERC721Enumerable {

/* VARIABLES */
    uint256 public currentId;

    address payable public beneficiary;
    address[] private _tokenAddrs;

    mapping(address => bool) public hasMinted;
    mapping(uint256 => string) private _tokenURIs;

    string public baseURI = "ipfs://";
    string public defaultMetadata = "QmavEQ84TMzbz7CEktD7SVE1vBQqeaBj4JGLXFgNmp3MPG";
    string private _contractURI = "QmXqtMKHL5AKQE8VhumF9aH5MeyPuwvd7m9KS5d22GKdhm";


/* CONSTRUCTOR */
    constructor (address payable init_beneficiary, address[] memory init_tokenAddrs) ERC721 ("PACDAO BONUS", "PAC-B"){
       beneficiary = init_beneficiary;
       _tokenAddrs = init_tokenAddrs;

    }


/* PUBLIC VIEWS */


    /**
     * @dev Returns eligible contracts for which users can claim a bonus if they have minted.
     *
     */
    function tokenAddrs() public view returns(address[] memory) {
	return _tokenAddrs;	
    }


    /**
     * @dev Returns number of NFTs the user would receive on mint.
     *
     */
    function userCap(address user) public view returns (uint) {
	uint count = 0;
	for(uint _i = 0; _i < _tokenAddrs.length; _i++) {
		address _addr = _tokenAddrs[_i];
		if(IERC721( _addr ).balanceOf(user) > 0) {
			count++;	
		}		
	}
	return count;
    }

    /**
     * @dev Return token URI if set or Default URI
     *
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(_exists(tokenId)); // dev: "ERC721URIStorage: URI query for nonexistent token";

	string memory _tokenURI = _tokenURIs[tokenId];
	string memory base = baseURI;

	// If there is no base URI, return the token URI.
	if (bytes(base).length == 0 && bytes(_tokenURI).length > 0) {
	   return _tokenURI;
	}

	// If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
	if (bytes(_tokenURI).length > 0) {
	   return string(abi.encodePacked(base, _tokenURI));
	}
	return string(abi.encodePacked(base, defaultMetadata)); 
    }

    /**
     * @dev Return contract URI
     *
     */
    function contractURI() public view returns(string memory) {
	return string(abi.encodePacked(baseURI, _contractURI));
    }
    

/* PUBLIC WRITEABLE */

    /**
     * @dev Mint NFT if eligible.
     *
     */

    function mint() public
	{
		uint _mintNum = userCap(msg.sender);
		require(_mintNum > 0, "No NFT Owned");
		require(hasMinted[msg.sender] == false, "Already Minted");

		for(uint _i = 0; _i < _mintNum; _i++) {
			_mint(msg.sender);
		}

		hasMinted[msg.sender] = true;
	}

    /**
     * @dev Recover funds inadvertently sent to the contract
     *
     */
    function withdraw() public 
    {
		beneficiary.transfer(address(this).balance);
    }


/* ADMIN FUNCTIONS */

    /**
     * @dev Admin function to mint an NFT for an address
     *
     */
    function mintFor(address _mintAddress) public payable
    {
	    require(msg.sender == beneficiary, "Only Admin");
	    _mint(_mintAddress);
    }

    /**
     * @dev Transfer ownership to new admin
     *
     */
    function updateBeneficiary(address payable _newBeneficiary) public 
    {		
	require(msg.sender == beneficiary, "Not owner");
	beneficiary = _newBeneficiary;
    }

    /**
     * @dev Stoke token URL for specific token
     *
     */
    function setTokenUri(uint256 _tokenId, string memory _newUri) public 
    {
	require(msg.sender == beneficiary, "Only Admin");
	_setTokenURI(_tokenId, _newUri);
    }

    /**
    * @dev Update default token URL when not set
    *
    */
    function setDefaultMetadata(string memory _newUri) public 
    {
	require(msg.sender == beneficiary); //dev: Only Admin
	defaultMetadata = _newUri;
    }

    /**
    * @dev Update contract URI
    *
    */
    function setContractURI(string memory _newData) public {
	require(msg.sender == beneficiary, "Only Admin");
	_contractURI = _newData;
    }	    

    /**
    * @dev Update eligible token addresses to receive mint
    *
    */
    function updateTokenAddrs(address[] memory _newTokenAddrs) public {
	require(msg.sender == beneficiary, "Only Admin");
	_tokenAddrs = _newTokenAddrs;
    }


/* INTERNAL FUNCTIONS */

    /**
    * @dev Update ID and mint
    *
    */
    function _mint(address _mintAddress) private {
	currentId += 1;
	_safeMint(_mintAddress, currentId);
    }


    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId)); // dev: ERC721URIStorage: URI set of nonexistent token
        _tokenURIs[tokenId] =  _tokenURI;
    }


/* FALLBACK */
	receive() external payable { }
	fallback() external payable { }


}
