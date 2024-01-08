//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./SafeERC20.sol";

contract BigAussieCrocs is ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    // Token detail
    struct BigAussieCrocsDetail {
        uint256 first_encounter;
    }

    mapping(address => bool) public whitelist;

    mapping(address=>uint256) public preSaleAmount;

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => BigAussieCrocsDetail) private _bigAussieCrocsDetails;

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

     // Max amount of token to presale purchase per account each time
    uint256 public PRESALE_MAX_PURCHASE = 5;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 9999;

    // Current price.
    uint256 public CURRENT_PRICE = 80000000000000000;

    // Define if sale is active
    bool public saleIsActive = false;

    // Define if presale is active
    bool public preSaleIsActive = false;

    // Base URI
    string private baseURI;

   /**
   * @dev Throws if called by any account is not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender],"Not a Whitelist Address");
    _;
  } 

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    /**
     * With
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
     
     /**
       WhiteList Addresses
      */
    function addAddressesToWhiteList(address[] memory addresses) public onlyOwner
    {
     for(uint i =0;i<addresses.length;i++)
     {
         whitelist[addresses[i]]=true;
     }
    }

    /*
     Whitelist SingleAddress
     */

    function addAddressToWhiteList(address userAddress) public onlyOwner
    {
        whitelist[userAddress]=true;
    }


    /**
      Remove from whitelist
     */
    function removeAddressFromWhiteList(address userAddress) public onlyOwner
    {
        whitelist[userAddress]=false;
    }

    /**
     * Reserve tokens
     */
    function reserveTokens() public onlyOwner {
        uint256 i;
        uint256 tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 50; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Mint a specific token.
     */
    function mintTokenId(uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId), "Token was minted");
        uint256 first_encounter = block.timestamp;
        _safeMint(msg.sender, tokenId);
        _bigAussieCrocsDetails[tokenId] = BigAussieCrocsDetail(first_encounter);
        emit TokenMinted(tokenId, msg.sender, first_encounter);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /*
     * Set max tokens
     */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /*
     * Pause presale if active, make active if paused
     */
    function setPreSaleState(bool newState) public onlyOwner {
        preSaleIsActive = newState;
    }

    /**
    
     */

     function mintFromWhiteList(uint256 numberOfTokens) public payable onlyWhitelisted {
         require(preSaleIsActive, "Mint is not available right now");
         require(
            numberOfTokens <= PRESALE_MAX_PURCHASE,
            "Can only mint 5 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of BigAussieCrocs"
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Value sent is not correct"
        );
        require(PRESALE_MAX_PURCHASE-preSaleAmount[msg.sender]-numberOfTokens>=0,"You have already minted your quota");
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _bigAussieCrocsDetails[tokenId] = BigAussieCrocsDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
        preSaleAmount[msg.sender]=preSaleAmount[msg.sender]+numberOfTokens;

     }

    /**
     * Mint BigAussieCrocs
     */
    function mintBigAussieCrocs(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of BigAussieCrocs"
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Value sent is not correct"
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _bigAussieCrocsDetails[tokenId] = BigAussieCrocsDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }    


    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /**
     * Get the token detail
     */
    function getBigAussieCrocsDetail(uint256 tokenId)
        public
        view
        returns (BigAussieCrocsDetail memory detail)
    {
        require(_exists(tokenId), "Token was not minted");

        return _bigAussieCrocsDetails[tokenId];
    }

}
