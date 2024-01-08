//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract CMoonsNFT is ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    // Token detail
    struct CMoonsDetail {
        uint256 first_encounter;
    }

    mapping(address => bool) public whitelist;

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => CMoonsDetail) private _cMoonsDetails;



    // Lottery Smart Contract Address
    address payable LOTTERY_ADDRESS = payable(address(0x9dE88867c73EBFE893b001dC93d188b3Af7c6760));

    address payable SHARE_1 = payable(address(0xD372627d8dBD99136265816857AB785eA54eFCf5));
    address payable SHARE_2 = payable(address(0x1543B3EE6e74Fc7c1f47a79924391C86d48066AF));
    address payable SHARE_3 = payable(address(0xD556Fb06dE2027Bf3C22935cc1291dbc96471c81));

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

     // Max amount of token to presale purchase per account each time
    uint256 public PRESALE_MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 3369;

    // Current price.
    uint256 public CURRENT_PRICE = 25000000000000000;

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
    require(whitelist[msg.sender],"Sorry, but this address is not on the whitelist. Please message us on Discord.");
    _;
  }

    /**
     * Contract constructor
     */
    constructor() ERC721("CMoonsNFT", "CMoons") {
    }

    /**
     * With
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance / 6);


        payable(SHARE_1).transfer(balance / 6);
        payable(SHARE_2).transfer(balance / 3);
        payable(SHARE_3).transfer(balance / 3);

    }

    receive() external payable {
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
        require(!_exists(tokenId), "Sorry, but this token was already minted.");
        uint256 first_encounter = block.timestamp;
        _safeMint(msg.sender, tokenId);
        _cMoonsDetails[tokenId] = CMoonsDetail(first_encounter);
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
         require(preSaleIsActive, "Presale minting is not available now.");
         require(
            numberOfTokens <= PRESALE_MAX_PURCHASE,
            "Only a maximum of 20 token per transaction can be minted during pre-sale."
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Exceeding maximum amount of available CryptoMoons NFT."
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Incorrect CryptoMoons NFT Price."
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _cMoonsDetails[tokenId] = CMoonsDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }


        if(tokenId > 2869 && tokenId <= MAX_TOKENS){
            LOTTERY_ADDRESS.transfer(0.05 ether);
        }
     }

    /**
     * Mint CMoons
     */
    function mintCMoons(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sorry, but the minting is not available now.");
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Sorry, but you can only mint 5 tokens total."
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Sorry, but we don't have that many Moons left."
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Sorry, but the value is inaccurate. Please take the number of Moons times 0.05"
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _cMoonsDetails[tokenId] = CMoonsDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }

        if(tokenId > 2869 && tokenId <= MAX_TOKENS){
            LOTTERY_ADDRESS.transfer(0.05 ether);
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

    function setShare1(address payable share1) public onlyOwner {
        SHARE_1= share1;
    }
    function setShare2(address payable share2) public onlyOwner {
        SHARE_2= share2;
    }
    function setShare3(address payable share3) public onlyOwner {
        SHARE_3= share3;
    }

    /**
     * Get the token detail
     */
    function getCMoonsDetail(uint256 tokenId)
        public
        view
        returns (CMoonsDetail memory detail)
    {
        require(_exists(tokenId), "This token was minted.");

        return _cMoonsDetails[tokenId];
    }

}