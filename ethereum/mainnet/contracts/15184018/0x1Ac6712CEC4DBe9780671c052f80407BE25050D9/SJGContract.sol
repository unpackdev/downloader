// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721A.sol";

contract SJGContract is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public MAX_SUPPLY     = 366;             // Max supply of thie collection 
    uint256 public MAX_PUB_MINT   = 10;             // Max pub mint # per wallet

    uint256 public PUB_SALE_PRICE = 0.03 ether;     // Price for public sale.
    uint256 public WL_SALE_PRICE  = 0.02 ether;     // Price for whitelist sale

    string private baseTokenURI;          // Base TokenURI                                
    string private prerevealTokenURI;     // Pre-reveal TokenURI  

    bool public isRevealed;        // Is the collection revealed?
    bool public isPubSale;         // Is it in the public sale mode?
    bool public isWLSale;          // Is it in the white list sale mode?
    bool public isPaused;          // Is it paused?

    mapping(address => uint256) public totalPubMint;    // Tracks how many minted per wallet for the public sale
    mapping(address => uint256) public whitelist   ;    // Tracks # if WL mint allowed per address.

    // We are only inheriting ERC721A straight.
    constructor() ERC721A("Sakura JK Gacha", "SJG"){}

    // This modifier make sure that it is not another contract calling this contract.
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Returns total number of tokens minted (different from totalSupply() inherited)
    function totalMinted() external view returns (uint256){
        return _totalMinted();
    }

    // Mint function for public mint.
    // 1.   Check not paused
    // 2.   Check that we are in public sale
    // 3&4. Check if the desired quantity exceeds maxsupply (MAX_SUPPLY) or personal max allowed (MAX_PUB_MINT)
    // 5.   Check if the price is more than publicsale * the desired quantity
    function pubMint(uint256 _quantity) external payable callerIsUser{
        require(!isPaused, "Minting is paused currently.");
        require(isPubSale, "We are not doing public sale now.");
        require((_totalMinted() + _quantity) <= MAX_SUPPLY, "You cannot exceed max supply.");
        require((totalPubMint[msg.sender] + _quantity) <= MAX_PUB_MINT, "Max public mint per wallet exceeded.");
        require(msg.value >= (PUB_SALE_PRICE * _quantity), "More Eth needed.");

        // Record the # minted.
        totalPubMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Mint function for wl mint.
    // 1.   Check not paused
    // 2.   Check that we are in WL sale
    // 3.   Check if the desired quantity exceeds maxsupply (MAX_SUPPLY)
    // 4.   Check if you have enough whitelist allowance.
    // Note that whitelist mint count will be decremented unlike the public sale one.
    // 5.   Check if the price is more than WL sale * the desired quantity
    function wlMint(uint256 _quantity) external payable callerIsUser{
        require(!isPaused, "Minting is paused currently.");
        require(isWLSale, "We are not doing WL sale now.");
        require((_totalMinted() + _quantity) <= MAX_SUPPLY, "You cannot exceed max supply.");
        require(whitelist[msg.sender] >= _quantity, "Max WL mint per wallet exceeded.");
        require(msg.value >= (WL_SALE_PRICE * _quantity), "Value too low.");

        whitelist[msg.sender] -= _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Set whitelist addresses and their allowed mint numbers.
    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner{
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = numSlots[i];
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // TokenURI Functoin to be called.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // If not revealed, show the placceholder token URI
        if(!isRevealed){
            return prerevealTokenURI;
        }

        // Else return the true address
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    // This _baseURI function is inherited from 721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Setter for base token URI.
    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenURI = _baseTokenUri;
    }

    // Setter for prereveal token URI.
    function setPlaceHolderUri(string memory _prerevealTokenURI) external onlyOwner{
        prerevealTokenURI = _prerevealTokenURI;
    }

    // Toggle Pause status
    function togglePause() external onlyOwner{
        isPaused = !isPaused;
    }

    // Toggle WhiteList status
    function toggleWhiteListSale() external onlyOwner{
        isWLSale = !isWLSale;
    }

    // Toggle Public status
    function togglePublicSale() external onlyOwner{
        isPubSale = !isPubSale;
    }

    // Toggle Reveal status
    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    // Standard withdraw function
    function withdraw() external onlyOwner{
        // Currently being sent to owner wallet.
        payable(msg.sender).transfer(address(this).balance);
    }
}