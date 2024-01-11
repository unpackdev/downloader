// SPDX-License-Identifier: Unknown

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./IERC2981.sol";
import "./Strings.sol";

/**
 * @title BSD NFT
 * 
 * Big Swinging Dick - Just like life, it's random, but if you're a true 
 * BSD you can certainly influence the outcome.  :)  
 *
 * Mint your BSD and roll the dice as your BSD traits are randomly generated
 * on chain.  If you feel like showing off, enhance your BSD mint and 
 * increase your odds joining the ranks of the Bull, Elephant or truly
 * rare Blue Whale Club with all the Big Dick Energy (BDE).
 *
 * Visit https://BSDnft.com to get your own permanent phallus (s/o to  
 * Ida Jonsson and Simon Saarinen - The Ethereum Big D OG)
 *
 */

contract BSD is ERC721Tradable, IERC2981 {
    
    constructor(address _proxyRegistryAddress) ERC721Tradable("Big Swinging Dick", "BSD", _proxyRegistryAddress) {
        
    }

// Structure is used in memory only, so not bit packed
    struct BsdStruct {
        uint length;
        uint girth;
        uint texture;
        uint shape;
        uint stamina;
        bool grower;
        bool gameOn;
        uint uses; 
        uint uhOh;
        uint vitality;
        uint bde;
    }

    uint256 public royalty = 500;
    bool private _active;
    bool private _salePaused;
    bool private _interactionEnabled;
    string private _baseTokenURI;
    string private _contractURI;
    address private _interactionContract;
    uint public constant TOKEN_LIMIT = 18888;
    uint private _price = 30_000_000_000_000_000;
    uint private _maxPrice = 4_030_000_000_000_000_001;
    uint private _enhancementPrice = 500_000_000_000_000_000;
    uint private _totalEnhancement;

    mapping (uint256 => bytes32) private _tokenIdToTraits;
    mapping (uint256 => string) private _tokenIdToName;

    event BsdSpotted(uint indexed tokenId, bytes32 traits);
    event BsdNamed(uint indexed tokenId, string name);

    /**
     * Read-only function to show details about the project.
     */ 
 
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Read-only function to retrieve metadata for a token.
     */ 
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
    }


    /**
     * Read-only function to determine if sale is active.  
     */
    function active() external view returns(bool) {
        return _active;
    }

    /**
     * Read-only function to retrieve the current price to mint a BSD.
     */
    function getMintPrice() public view returns (uint256) {
        require(_active, "Not active");
        return _price;
    }

    /**
     * Read-only function to retrieve the maximum allowed price to mint a BSD.
     */
    function getMaxPrice() public view returns (uint256) {
        require(_active, "Not active");
        return _maxPrice;
    }

    /**
     * Read-only function to retrieve the current price for maximum enhancement.
     */
    function getEnhancementPrice() public view returns (uint256) {
        require(_active, "Not active");
        return _enhancementPrice;
    }

    /**
     * Read-only function to retrieve current price to mint a BSD, the maximum price,
     * and the enhancement price.
     */

    function showPrices() public view returns (uint mintP, uint maxP, uint enhanceP){
        return (getMintPrice(), getMaxPrice(), getEnhancementPrice());
    }

    /**
     * Read-only function to retrieve the name a user gave to their BSD.
     */
    function tokenName(uint256 tokenId) public view returns (string memory){
        return _tokenIdToName[tokenId];
    }

    /**
     * Function to show traits of a token
     */
    function tokenDescription(uint256 tokenId) public view returns (string memory){
        require(tokenId <= totalSupply(), "Token does not exist");
        (BsdStruct memory bsdData) = tokenDescriptionArray(tokenId);
        return tokenDescriptionFromBsd(bsdData);
    }

    function tokenDescriptionFromBsd(BsdStruct memory bsdData) private pure returns (string memory){     
        string memory lString = Strings.toString(bsdData.length);
        string memory lStringImperial = _cmToInchString(bsdData.length);
        string memory gString = Strings.toString(bsdData.girth);
        string memory gStringImperial = _cmToInchString(bsdData.girth);
        string memory tString = "smooth";
        string memory stString = "normal";
        if (bsdData.stamina == 0) {
            stString = "early shooter";
        }
        else if (bsdData.stamina == 2){
            stString = "marathon man";
        }
        if (bsdData.texture < 2) {
            tString = "veiny";
        }
        else if (bsdData.texture == 2){
            tString = "bumpy";
        }
        else if (bsdData.texture == 4){
            tString = "hairy";
        }
        string memory sString = "straight";
        if (bsdData.shape == 1) {
            sString = "mushroom";
        }
        else if (bsdData.shape == 2) {
            sString = "cone";
        }
        else if (bsdData.shape == 3){
            sString = "eggplant";
        } 
        else if (bsdData.shape == 4) {
            sString = "asparagus";
        }
        else if (bsdData.shape == 5) {
            sString = "banana";
        }
        string memory cString = bsdData.grower ? "grower" : "shower";
        string memory rString = string(abi.encodePacked("length: ",lString,"cm / ", lStringImperial,"in, girth: ", gString,"cm / ", gStringImperial, "in, shape: "));
        rString = string(abi.encodePacked(rString, sString, ", texture: ", tString, ", grower/shower: ", cString, ", stamina: ", stString)); 
        rString = string(abi.encodePacked(rString, ", bde: ", Strings.toString(bsdData.bde), ", uses: ", Strings.toString(bsdData.uses)));
        rString = string(abi.encodePacked(rString,", vitality: ", Strings.toString(bsdData.vitality), ", uhOh: ",Strings.toString(bsdData.uhOh)));
        return rString;
     }

    /**
     * Read-only function to retrieve a tokens traits.
     */

    function tokenDescriptionArray(uint256 tokenId) public view returns (BsdStruct memory) {
        return bsdArray(getRawTraits(tokenId));
    }

    /**
     * Read-only function to retrieve the raw traits information.
     */

    function getRawTraits(uint256 tokenId) public view returns (bytes32) {
        return _tokenIdToTraits[tokenId];
    }

    /**
    *   Internal function the computes traits from bytes32.
    */

    function bsdArray(bytes32 bsd) private pure returns (BsdStruct memory bsdData){
        bsdData.texture = _getBitsFromBytesAsUint(bsd, 3, 0);
        bsdData.shape = _getBitsFromBytesAsUint(bsd, 3, 1);
        bsdData.grower = _getBitsFromBytesAsUint(bsd, 3, 2) < 7 ? true : false;
        uint st = 0; 
        for (uint s = 0; s < 8; s++) {
            st = st + _getBitsFromBytesAsUint(bsd,2,s * 6 + 4);
        }
        bsdData.stamina = 1;
        if(st < 9){
            bsdData.stamina = 0;
        }
        else if (st > 19){
            bsdData.stamina = 2;
        }
        bsdData.gameOn = _getBitsFromBytesAsUint(bsd, 1, 255) == 1 ? true : false;
        bsdData.uses = _getBitsFromBytesAsUint(bsd, 3, 84);
        bsdData.uhOh = _getBitsFromBytesAsUint(bsd, 2, 125);
        bsdData.vitality = 3 - _getBitsFromBytesAsUint(bsd, 2, 124);

        uint l;
        uint length;

        // Using the central limit thereom for a normal distribution.
        for (l = 0; l < 31; l++){
            uint _addand = _getBitsFromBytesAsUint(bsd, 8, l);
            length = length + (_addand > 172 ? 128 : 0) + _addand;
        }

        if (length > 248){
            length = length - 248;
        }

        bsdData.length = length / 248 ;

        uint g;
        uint girth;

        for (g = 0; g < 41; g++){
            uint _gAddand = _getBitsFromReversedBytesAsUint(bsd, 8, 6, g);
            girth = girth + (_gAddand > 50 ? 60 : 0) + _gAddand;
        }

        girth = (girth + 960);
        bsdData.girth = girth / 192;

        bsdData.bde = (bsdData.girth * bsdData.girth * bsdData.length) / 1131;
    }

    /**
     * Read-only function to retrieve the total number of NFTs that have been minted thus far
     */
    function getTotalMinted() external view returns (uint256) {
        return totalSupply();
    }
   

// Royalty info
    function royaltyInfo (
            // solhint-disable-next-line no-unused-vars
            uint256 _tokenId,
            uint256 _salePrice
        ) external view override(IERC2981) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            // Royalty payment is 5% of the sale price
            uint256 royaltyPmt = _salePrice*royalty/10000;
            require(_tokenId < totalSupply(), "Invalid token");
            require(royaltyPmt > 0, "Royalty must be greater than 0");
            return (address(this), royaltyPmt);
        }

// Callable functions 

/**
*  Mint your BSD.
*/
    function mint() external payable {
        require(_active == true && !_salePaused, "Sale not active");
        require(totalSupply() < TOKEN_LIMIT, "Sold out");
        require(balanceOf(msg.sender) == 0 || msg.value >= _enhancementPrice || msg.value >= (_maxPrice - _price), "Max of one base price BSD");
        require(msg.value >= _price && msg.value <= _maxPrice, "Invalid amount sent");
        uint tokenId = _mintTo(msg.sender);
        bytes32 attributes = _generateAttributes(tokenId, msg.value);
        _tokenIdToTraits[tokenId] = attributes;
    }

/**
*   Everyone has a pet name for their BSD.
*/

    function nameMyBSD(uint idToken, string memory name) external payable{
        require(ERC721.ownerOf(idToken) == msg.sender, "Not the owner");
        require(msg.value == _price, "Invalid amount sent");
        _tokenIdToName[idToken] = name;
        emit BsdNamed(idToken, name);
    }

/**
*   Allow the external game to interact with your token.
*/

    function toggleGameOnForToken(uint idToken) external payable {
        require(ERC721.ownerOf(idToken) == msg.sender, "Not the owner");
        require(msg.value == _price, "Invalid amount sent");
        bytes32 current = _tokenIdToTraits[idToken];
        uint currentSet = _getBitsFromBytesAsUint(current, 1, 255);
        current = ((current << 1) >> 1);
        bytes32 mask = hex"80";
        if (currentSet == 1){
            mask = ~mask;
            current = current & mask;
        }
        else{
            current = current | mask;
        }
        _tokenIdToTraits[idToken] = current;
    }

/**
*   Functions to generate attributes for newly minted BSD tokens.
*/

    function _generateAttributes(uint tokenId, uint bdprice) private returns (bytes32) {
        bytes32 randomAttributes = _random(tokenId);
        
        if (bdprice >  _price){
            uint max = bdprice > (_enhancementPrice + _price) ? (_enhancementPrice + _price) : bdprice; 
            uint n = (112 * (max -  _price)) / _enhancementPrice;
            bytes32 randomAddition = _random160(tokenId);
            randomAddition = randomAddition << (160 - n);
            randomAddition = randomAddition >> (240 - n);
            randomAttributes = randomAttributes |  randomAddition;
            uint fraction = 40000 * (max - _price) / _enhancementPrice;
            uint add = fraction * _enhancementPrice / 10000000;
            // Each time a token is generated with enhancement, we increase the enhancement price.
            _enhancementPrice = _enhancementPrice + add;
        }

        // The first byte is reserved for the interacting contract
        return (randomAttributes >> 8);
    }

    /**
    * Utility functions used internally
    **/

    function _random(uint tokenId) private view returns (bytes32) {
        return (keccak256(abi.encodePacked(tokenId, block.timestamp, blockhash(block.number - 1))));
    }

    function _random160(uint tokenId) private view returns (bytes32) {
        return ((keccak256(abi.encodePacked(block.difficulty, block.timestamp,tokenId))) << 96) ;
    }

    function _getBitsFromBytesAsUint(bytes32 input, uint bits, uint position) private pure returns (uint){
        
        bytes32 temp = input >> (position * bits);
        bytes32 mask = bytes32(uint256(2 ** bits - 1));
        temp = temp & mask;
        return uint(temp);
    }

    function _getBitsFromReversedBytesAsUint(bytes32 input, uint offset, uint bits,  uint position) private pure returns (uint){
        bytes32 temp = input >> (256 - offset - ((position + 1) * bits));
        bytes32 mask = bytes32(uint256(2 ** bits - 1));
        temp = temp & mask;
        uint i = 0;
        uint m = 1;
        uint total = 0;
        mask  = bytes32(uint256(1));
        for(i = 0; i < bits; i++){
            bytes32 temp2 = temp >> (bits - i - 1);
            temp2 = temp2 & mask;
            uint tempUint = uint(temp2);
            total = total + (m * tempUint);
            m = m * 2;
        }
        return total;
    }

    function _cmToInch(uint cm) private pure returns (uint whole, uint part) {
            whole = (cm * 100) / 254;
            uint remainder = (cm * 100) % 254;
            part = (remainder * 100 + 1270) / 2540;
            if (part == 10){
                whole = whole + 1;
                part = 0;
            }
        }

    function _cmToInchString(uint cm) private pure returns (string memory){
        (uint gImp, uint gImpDec) = _cmToInch(cm);
        return string(abi.encodePacked(Strings.toString(gImp), ".", Strings.toString(gImpDec)));
    }

/*
* Game function for interacting contract - can only be enabled by owner of NFT.
*/
    function gameOn(bytes1 newTraits, uint idToken) external {
        require(_interactionEnabled == true, "Invalid call");
        require(msg.sender == _interactionContract, "Invalid call");
        require(msg.sender != address(0), "Invalid call");
        bytes32 modifyTraits = _tokenIdToTraits[idToken];
        uint enabled = _getBitsFromBytesAsUint(modifyTraits, 1, 255);
        require(enabled == 1, "Invalid call");
        bytes1 newTrait = ((newTraits << 1) >> 1) | bytes1(uint8(0x80));
        bytes32 mask = bytes32(newTrait);
        modifyTraits = (modifyTraits << 8) >> 8;
        _tokenIdToTraits[idToken] = modifyTraits | mask;
    }
    
// Owner functions

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }
    
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function startSale() external onlyOwner {
        require(!_active, "Already active");
        _active = true;
    }

    function updateSaleParams(uint setPrice, uint enhancePrice, uint maxPrice) external onlyOwner {
        require(_active, "Not active");
        _price = setPrice;
        _maxPrice = maxPrice;
        _enhancementPrice = enhancePrice;
    }
  
    function pauseSale(bool paused) external onlyOwner {
        _salePaused = paused;
    }

    function setInteractingContract(bool isActive, address interacting) external onlyOwner {
        _interactionEnabled = isActive;
        _interactionContract = interacting;
    }

    function mintBSD(address recipient) external payable onlyOwner {
        require(_active == true && !_salePaused, "Sale not active");
        require(totalSupply() < TOKEN_LIMIT, "Sold out");
        require(msg.value >= _price && msg.value <= _maxPrice && msg.value <= (_enhancementPrice + _price), "Invalid amount sent");
        uint tokenId = _mintTo(recipient);
        bytes32 attributes = _generateAttributes(tokenId, msg.value);
        _tokenIdToTraits[tokenId] = attributes;
    }

}