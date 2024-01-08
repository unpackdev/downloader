// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Dorkis.sol";
import "./Royalties.sol";

contract HalloweenDorkis is Ownable, ERC721Enumerable , Royalties  {
    using SafeMath for uint256;
    
    uint256 public tokenPrice = 70000000000000000; //0.07 ETH
    uint256 public MAX_TOKENS;
    uint256[] private royalties = new uint256[](1);
    
    uint public constant MAX_PURCHASE = 25;
    uint public constant MAX_RESERVE = 30;
    uint private maxPayedMint=350;
    uint private payedMintCounter;
    
    bool public saleIsActive;
    bool public freeMintIsActive;
    bool public payedMintRestrictionActive = true;
    bool[] private hasMinted;
    
    Dorkis private dorkis;
    address payable[] private addr = new address payable[](1);
    address private dorkisContract  = 0x0588a0182eE72F74D0BA3b1fC6f5109599A46A9C;
    address private constant TORI = 0x51Be0a47282afbE3a330F7738A0Ab5b277810Fe4;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant FCCVIEW = 0xf450a5d6C4205ca8151fb1c6FAF49A02c8A527FC;
    
    // Base URI for Meta data
    string private _baseTokenURI;
    event priceChange(address _by, uint256 price);
    event PaymentReleased(address to, uint256 amount);
    
    constructor() ERC721("Halloween Dorkis", "HDRK") {
        MAX_TOKENS = 4724;
        hasMinted = new bool[](MAX_TOKENS);
        _baseTokenURI = "ipfs://QmcYM19E4jkj996BPBJtYvSf9DDj4UrQpcJQNaxoeLELTU/";
        dorkis = Dorkis(payable(dorkisContract));
        addr[0]=payable(owner());
        royalties[0]=650; //6.5 % on Rarible
        _safeMint(TORI, 0);
        _safeMint(FRANK, 1);
        _safeMint(FCCVIEW, 2);
        hasMinted[0]=true;
        hasMinted[1]=true;
        hasMinted[2]=true;
    }
    
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override (ERC721Enumerable,Royalties) returns  (bool){
        return ERC721.supportsInterface(interfaceId) || Royalties.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
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
    
        /**
    * Get all tokens for a specific wallet
    * 
    */
    function getDorkisForAddress(address fromAddress) external view returns (uint256 [] memory){
        return dorkis.getTokensForAddress(fromAddress);
    }
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    /**
     * Pause sale if active, make active if paused
     */
    function flipFreeMintState() public onlyOwner {
        freeMintIsActive = !freeMintIsActive;
    }
    
    /**
     * Deactivate MintRestriction if active, make active if deactivated
     */
    function flipMintRestrictionState() public onlyOwner {
        payedMintRestrictionActive = !payedMintRestrictionActive;
    }
    /**
     * Set the max number of Payed Mints.
     */
    function setMaxPayedMint(uint maxPayedMintCounter) public onlyOwner{
        maxPayedMint=maxPayedMintCounter;
    }
    
     /**    
    * Set Dorkis contract address
    */
    function setDorkisContract(address newAddress) public onlyOwner {
         dorkis = Dorkis(payable(newAddress));
    }
    /**    
    * Set provenance once it's calculated
    */
    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }
    
    function numberOfMintsForArray(uint256 [] memory dorkisMinted) external view returns (uint){
        uint counter = 0;
        for (uint id = 0; id < dorkisMinted.length; id++) {
            if(!hasMinted[dorkisMinted[id]]){
                counter += 1;
            }
        }
        return counter;
    }

    /**
     * Mint PAYED Dorkis
     */
    function mintHalloweenDorkis(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Dorkis.");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        if(payedMintRestrictionActive){
            require(payedMintCounter<maxPayedMint+numberOfTokens,"Purchase would exceed max supply of payed mint Dorkis");
        }
        preMintChecks(numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                payedMintCounter +=1;
            }
        }
    }
    
    /**
     * Set some Dorkis aside for giveaways.
     */
    function reserveDorkis() public onlyOwner {    
        require(totalSupply().add(MAX_RESERVE) <= MAX_TOKENS, "Reserve would exceed max supply of Dorkis");
        uint supply = totalSupply();
        for (uint i = 0; i < MAX_RESERVE; i++) {
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, supply + i);
                payedMintCounter +=1;
            }
        }
    }
    

    /**
     * Mint FREE Haloween Dorkis
     */
    function mintFreeHalloweenDorkis(uint numberOfTokens) public {
        require(freeMintIsActive, "Free Mint Sale must be active to mint the Free Dorkis");
        uint256 [] memory dorkisMinted = dorkis.getTokensForAddress(msg.sender);
        require(numberOfTokens<=this.numberOfMintsForArray(dorkisMinted),"Trying to mint more Halloween Dorkis, then unused Dorkis.");
        preMintChecks(numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                setMintedTrue(dorkisMinted);
            }
        }
    }
    
    function setMintedTrue(uint256 [] memory dorkisMinted) private{
        uint counter=0;
        while(counter<dorkisMinted.length){
            if(hasMinted[dorkisMinted[counter]]){
                counter += 1;
            }else{
                hasMinted[dorkisMinted[counter]] = true;
                break;
            }
        }
    }
    
    function preMintChecks(uint numberOfTokens) internal view {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0.");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 25 tokens at a time.");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Dorkis");
    }
    
    function getMintedDorkis() public view returns (bool [] memory){
        return hasMinted;
    }
    
    function withdraw() public onlyOwner {
        uint256 artists = address(this).balance / 5;
        require(payable(TORI).send(artists));
        require(payable(FRANK).send(artists));
        require(payable(FCCVIEW).send(artists));
        require(payable(owner()).send(artists*2));
        emit PaymentReleased(owner(), artists*2);
    }
    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
    
    // Royalties implemetations 

    function getFeeRecipients(uint256 tokenId) external view override returns (address payable[] memory){
        require(_exists(tokenId), "EVIL DORKIS: FeeRecipients query for nonexistent token");
        return addr;
    }
    // fees.value is the royalties percentage, by default this value is 1000 on Rarible which is a 10% royalties fee.
    function getFeeBps(uint256 tokenId) external view override returns (uint[] memory){
        require(_exists(tokenId), "EVIL DORKIS: FeesBPS query for nonexistent token");
        return royalties;
    }

    function getFees(uint256 tokenId) external view override returns (address payable[] memory, uint256[] memory){
        require(_exists(tokenId), "EVIL DORKIS: Fees query for nonexistent token");
        return (addr, royalties);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256){
        require(_exists(tokenId), "EVIL DORKIS: royaltyInfo query for nonexistent token");
        return (address(this),(salePrice*royalties[0]/10000));
    }
    
}