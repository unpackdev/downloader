// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;


import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Royalties.sol";

/**
 * @title LazySloths contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 * 
 */
 //  Twitter @FrankPoncelet
 //
contract LazySloths is Ownable, ERC721Enumerable, Royalties {
    using SafeMath for uint256;

    uint256 public tokenPrice = 50000000000000000; //0.05 ETH
    uint256 public MAX_SLOTHS;
    
    uint public constant MAX_PURCHASE = 20;
    uint public constant MAX_RESERVE = 30;

    bool public saleIsActive;
    
    address payable[] private addr = new address payable[](1);
    uint256[] private royalties = new uint256[](1);
    
    // Base URI for Meta data
    string private _baseTokenURI = "ipfs://QmetbFFTF51b78BADpgB4px18Bct25yjstRrsDH4wj7J4w/";  
    string public SLOTHS_PROVENANCE = "";

    address private constant DAO = 0x8ef4268e320bAEfBF2499cF9cEfe67177e5D8649;
    
    event priceChange(address _by, uint256 price);
    event PaymentReleased(address to, uint256 amount);

    constructor() ERC721("The Lazy Sloths", "SLOTHS") {
        MAX_SLOTHS = 9973; 
        addr[0]=payable(owner());
        royalties[0]=500; //5 % on Rarible
        _safeMint( DAO, 0);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override (ERC721Enumerable,Royalties) returns  (bool){
        return ERC721.supportsInterface(interfaceId) || Royalties.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }
    
    /**     
    * Set price 
    */
    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }
    
    function withdraw() public onlyOwner {
        uint256 artists = address(this).balance / 5;
        require(payable(DAO).send(artists*2));
        require(payable(owner()).send(artists*3));
        emit PaymentReleased(owner(), artists*3);
    }

    /**
     * Set some Dorkis aside for giveaways.
     */
    function reserveTokens() public onlyOwner {    
        require(totalSupply().add(MAX_RESERVE) <= MAX_SLOTHS, "Reserve would exceed max supply of Dorkis");
        uint supply = totalSupply();
        for (uint i = 0; i < MAX_RESERVE; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /*     
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SLOTHS_PROVENANCE = provenanceHash;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. 
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Set the base token URI
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    

    /**
     * Mints Sloths
     */
    function mintSloths(uint numberOfTokens) public payable {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_SLOTHS, "Purchase would exceed max supply of tokens");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SLOTHS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
    function preSale(address _to, uint256 numberOfTokens) external onlyOwner() {
        require(totalSupply().add(numberOfTokens) <= MAX_SLOTHS, "Reserve would exceed max supply of tokens");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 20 tokens at a time");
        uint256 supply = totalSupply();
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( _to, supply + i );
        }
    }
    
   /**
    * Get all tokens for a specific wallet
    * 
    */
    function getTokensForAddress(address fromAddress) external view returns (uint256 [] memory){
        uint tokenCount = balanceOf(fromAddress);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(fromAddress, i);
        }
        return tokensId;
    }
    
    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }

    // Royalties implemetations 

    function getFeeRecipients(uint256 tokenId) external view override returns (address payable[] memory){
        require(_exists(tokenId), "LazySloths: FeeRecipients query for nonexistent token");
        return addr;
    }
    // fees.value is the royalties percentage, by default this value is 1000 on Rarible which is a 10% royalties fee.
    function getFeeBps(uint256 tokenId) external view override returns (uint[] memory){
        require(_exists(tokenId), "LazySloths: FeesBPS query for nonexistent token");
        return royalties;
    }

    function getFees(uint256 tokenId) external view override returns (address payable[] memory, uint256[] memory){
        require(_exists(tokenId), "LazySloths: Fees query for nonexistent token");
        return (addr, royalties);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256){
        require(_exists(tokenId), "LazySloths: royaltyInfo query for nonexistent token");
        return (address(this),(salePrice*royalties[0]/10000));
    }
}