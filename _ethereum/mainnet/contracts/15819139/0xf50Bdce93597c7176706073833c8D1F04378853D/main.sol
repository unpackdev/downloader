// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721URIStorage.sol";
import "ERC721Burnable.sol";
import "MerkleProof.sol";
import "ERC721.sol";
import "Pausable.sol";
import "Ownable.sol";
import "Counters.sol";
import "Strings.sol";

/// @custom:security-contact svmorris@protonmail.com
contract BoredtoDeath is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint8   public freeMints   = 2;
    uint8   public maxPerWL    = 10;
    bool    public publicSale  = false;
    bool    public isRevealed  = false;
    uint256 public totalSupply = 1111;
    uint256 public mintPrice   = 5000000000000000;
    string  public baseURI     = "ipfs://"; // will change to IPFS directory at reveal
    bytes32 public merkleRoot;
    mapping(string => uint256) public mintedURItoId;


    // User groups
    address[] public admins; // Fixed array at construction, cannot be changed later.
    mapping(address => uint16) public amountMinted;



    constructor(string memory _placeholderTokenURI, bytes32 _merkleRoot, address[] memory _admins) payable ERC721("Bored To Death v2", "BTD")
    {
        // Admins must be defined at the construction of the contract
        // and cannot be changed later on.
        admins = _admins;

        // Make sure tokens start from 1 rather than uint16
        _tokenIdCounter.increment();

        // NOTE: The baseURI has to have a / at the end
        baseURI = string.concat(baseURI, _placeholderTokenURI, "/");

        // Set merkle root
        merkleRoot = _merkleRoot;
    }


    // Modifiers
    // --------------------------------------------------------------------------------------


    modifier beforeReveal
    {
        require(isRevealed == false, "This function is no longer working after the reveal.");
        _;
    }
    
    modifier afterReveal
    {
        require(isRevealed == true, "Token has not yet been revealed");
        _;
    }

    modifier onlyAdmin
    {
        bool foundAdmin = false;
        for (uint8 i = 0; i < admins.length; i++)
        {
            if (admins[i] == msg.sender)
                foundAdmin = true;
        }

        require(foundAdmin, "Only an admins can access this function");
        _;
    }



    // State and information
    // --------------------------------------------------------------------------------------


    function _baseURI() internal view override returns (string memory)
    {
        return baseURI;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /*
     * @notice Return the total number of minted tokens.
     */
    function minted() public view returns(uint256)
    {
        return _tokenIdCounter.current() -1; // Because we are not counting from 0
    }


    // Other
    // --------------------------------------------------------------------------------------


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }



    // Admin tools
    // --------------------------------------------------------------------------------------


    /*
     * @notice Mint function to be used by all other functions
     *      if they need to mint a new token.
     *
     *      Its best to keep this centralised, so no other
     *       function should call _mint or _safeMint directly.
     */
    function mintInternal(address to) internal
    {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= totalSupply, "Cannot Mint any more tokens");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, Strings.toString(tokenId));
    }


    /*
     * @notice Pause transfers of NFT's
     */
    function pause() onlyAdmin public
    {
        _pause();
    }

    /*
     * @notice Resume transfers of NFT's
     */
    function unpause() onlyAdmin public
    {
        _unpause();
    }


    function setPublicSale(bool value) onlyAdmin public
    {
        publicSale = value;
    }

    /*
     * @notice Function allows an admin to mint tokens for free and send them
     *      to an arbitrary address. This is used for airdrops before reveal.
     */
    function adminMint(address to, uint256 amount) onlyAdmin beforeReveal public
    {
        require(_tokenIdCounter.current() < totalSupply, "No more tokens to mint!");

        for (uint8 i = 0; i < amount; i++)
        {
            mintInternal(to);
        }
    }


    /*
     * @notice Admins can burn tokens if they need to.
     */
    function burnToken(uint256 _tokenId) onlyAdmin public
    {
        _burn(_tokenId);
    }


    /*
     * @notice Withdraw ether from the contract.
     *      The amount set will be sent to each admin, so there
     *      must be at least amount * admins.length ether in the
     *      contract.
     */
    function withdraw(uint256 amount) onlyAdmin public
    {
        for (uint8 i = 0; i < admins.length; i++)
        {
            payable(admins[i]).transfer(amount);
        }
    }


    /*
     * @notice Set the mint price for second time minters or
     *      the public.
     */
    function setMintPrice(uint256 _priceInWei) onlyAdmin public
    {
        mintPrice = _priceInWei;
    }


    /*
     * @notice Update the merkle root if we needed to change
     *          the whitelist.
     *
     * @dev This is also a simple way of controlling when people
     *      can mint.
     */
    function setMerkleRoot(bytes32 _merkleRoot) onlyAdmin public
    {
        merkleRoot = _merkleRoot;
    }


    /*
     * @notice Change the placeholder URI to an ipfs folder
     *      where all the json files are stored. 
     * 
     * @dev This is not set to before reveal only as we might
     *      fuck it up and need to change it again.
     *
     */
    function reveal(string memory _folder_uri) onlyAdmin public
    {
        baseURI = string.concat("ipfs://", _folder_uri, "/");
    }

    

    // Whitelist tools
    // --------------------------------------------------------------------------------------


    /*
     * @notice Allow white-listed accounts to mint up to 10 tokens, with the first 2 being free
     *          these numbers can change ofc with instance variables: maxPerWL and freeMints
     */
    function whiteListMint(uint16 amount, bytes32[] memory _merkleProof) beforeReveal public payable
    {

        // Verify that the account is on the whitelist with merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are not on the whitelist");


        // NOTE: If there is any other method that needs these checks
        //        then break it out into a modifier

        require(amount > 0, "You have to mint at least one token");

        // Calculate how many free mints the wallet still has
        uint16 free;
        if (amountMinted[msg.sender] > freeMints)
            free = 0;
        else
            free = freeMints - amountMinted[msg.sender];

        // Calculate the price of the mint after excluding the free mints
        if (free < amount)
            require(msg.value >= (amount-free)*mintPrice, "Not enough ETH sent for minting this many tokens.");


        // Make sure the wallet doesn't overstep its limit
        require(amountMinted[msg.sender] + amount <= maxPerWL, "Overstepped the maximum mint per white listed wallet.");


        // Add to the already minted counter
        // It's better to do this here than in mintInteral for a few reasons:
        // - We don't want airdrops to take a way from the free and allowed mints.
        // - We can do it in one step instead of with a loop to hopefully save gas.
        amountMinted[msg.sender] += amount;


        for (uint16 i = 0; i < amount; i++)
            mintInternal(msg.sender);
    }



    // Public mint
    // --------------------------------------------------------------------------------------

    /*
     * @notice function handles public mint if we need to switch from wl only.
     */
    function publicMint(uint16 amount) beforeReveal public payable
    {
        require(publicSale == true, "The public sale has not yet been opened. This will only open if there are issues with the wl.");
        require(amount > 0, "Must mint at least one token.");
        require(msg.value >= amount * mintPrice, "Not enough ETH sent for minting this many tokens");
        // NOTE: there is just no use restricting the amount of tokens per wallet on a public mint.

        amountMinted[msg.sender] += amount;

        for (uint16 i = 0; i < amount; i++)
            mintInternal(msg.sender);
    }
}
