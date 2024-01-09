// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "imports.sol";

/* Bonus token for holders of any PAC DAO NFT */
contract PACLEXAction is ERC721Enumerable {

/* VARIABLES */
    uint256 public currentId;
    address payable public beneficiary;
    address public owner;

    address public pacdao = 0xf27AC88ac7e80487f21e5c2C847290b2AE5d7B8e;
    address public lexarmy = 0xBe9aAF4113B5a4aFCdb7E20c21eAa53C6EE20b10;
    address public artist = 0x82fDAF8ceD639567dEd54447400b037C4D0719d5;

    mapping(uint256 => string) private _tokenURIs;
    mapping(bytes32 => uint256) private leafMints;

    uint256 maxMintsPerLeaf = 1;

    string public baseURI = "ipfs://";
    string public defaultMetadata = "QmTYvCgKunY8W18kSpCK5eUpHSEzGCmzqQp185AU451ALV";
    string private _contractURI = "Qma4VAp8giZ74Ny7jJVW1e5V8kmC5VVaSeF6cbXWFizxsr";

    bool isPublicMint = true;

    bytes32 private merkleRoot;

/* CONSTRUCTOR */
    constructor () ERC721 ("PAC/LEX Action", "PACLEX-A1"){
       owner = msg.sender;
       beneficiary = payable(0xf27AC88ac7e80487f21e5c2C847290b2AE5d7B8e);
       merkleRoot = 0xbec6093988d4c88c0ee9b16c888f45b54e42106c79b3244b0a5551c0d4191f26; 
    }


/* PUBLIC VIEWS */

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

	// No Token URI, return default
	return string(abi.encodePacked(base, defaultMetadata)); 
    }

    /**
     * @dev Return contract URI
     *
     */
    function contractURI() public view returns(string memory) {
	return string(abi.encodePacked(baseURI, _contractURI));
    }
    

/*f = PUBLIC WRITEABLE */

    /**
     * @dev Mint NFT if eligible.
     *
     */

    function mint(bytes32 leaf, bytes32[] memory proof) public
	{
		require(isPublicMint); // dev: Minting period over
		require(verifyMerkle(leaf, proof)); // dev: Invalid Merkle Tree
		require(leafMints[leaf] < maxMintsPerLeaf); // dev: Leaf already used
		leafMints[leaf] += 1;
		_mint(msg.sender);
		if(currentId < 3) {
			_mint(artist);
		}
		if(currentId < 36) {
			_mint(pacdao);
			_mint(lexarmy);
		}
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
	    require(msg.sender == beneficiary); // dev: Only Admin
	    require(_mintAddress != address(0));
	    _mint(_mintAddress);
    }

    function updateRoot(bytes32 newRoot) public {
	require(msg.sender == beneficiary); // dev: Only Admin
	merkleRoot = newRoot;
    }

    /**
     * @dev Transfer ownership to new admin
     *
     */
    function updateBeneficiary(address payable newBeneficiary) public 
    {		
	require(msg.sender == beneficiary); // dev: Only Admin
	beneficiary = newBeneficiary;
    }

    function transferOwner(address newOwner) public {
	require(msg.sender == beneficiary || msg.sender == owner); // dev: Only Owner
	owner = newOwner;
    }

    function updatePublicMint(bool isMint) public {
	require(msg.sender == beneficiary); // dev: Only Admin
	isPublicMint = isMint;
    }

    function updateMaxMintsPerLeaf(uint256 newMax) public {
	require(msg.sender == beneficiary); // dev: Only Admin
	maxMintsPerLeaf = newMax;
    }

    /**
     * @dev Stoke token URL for specific token
     *
     */
    function setTokenUri(uint256 _tokenId, string memory _newUri) public 
    {
	require(msg.sender == beneficiary); // dev: Only Admin
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
	require(msg.sender == beneficiary); //dev: Only Admin
	_contractURI = _newData;
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


    function verifyMerkle(bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
     bytes32 computedHash = leaf;
     for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided rootA
    return computedHash == merkleRoot;

    }


/* FALLBACK */
	receive() external payable { }
	fallback() external payable { }


}
