// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract SativaJazzJH is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string _baseTokenURI = "https://api.abanamusic.com/jh/";
    address private ash = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92; //production

    bool public preSaleActive = false;
    bool public publicSaleActive = false;

    mapping (address => uint256) public greenList;
    mapping (address => uint256) public holdersList;

    mapping (uint256 => uint256) public tokenColorIds;

    constructor() ERC721("SativaJazzJH", "SJJH") {}

    function updateBaseURI(string memory newbaseURI) public onlyOwner {
        _baseTokenURI = newbaseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawAllEth() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function togglePreSale(bool active) public onlyOwner {
        preSaleActive = active;
    }

    function togglePublicSale(bool active) public onlyOwner {
        publicSaleActive = active;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function checkSupply() internal view{
        uint256 _supply = totalSupply();
        // Check available supply
        require(_supply + 1 < 112,                   "Exceeds maximum supply");
    }

    function mintHolders() public payable whenNotPaused {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 16900000000000000; // 0.0169 ETH
        require(msg.value == price,                  "Ether sent is not correct");
        checkSupply();
        safeMintHolders();
    }

    function mintHoldersAsh() public whenNotPaused {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 6.9 * 10 ** 18; // 6.9 ash approx 0.0169 ETH
        require(IERC20(ash).transferFrom(msg.sender, owner(), price), "$ASH transfer failed");
        checkSupply();
        safeMintHolders();
    }

    function safeMintHolders() internal {
        uint256 preSaleAllowed = holdersList[msg.sender];
        require(preSaleAllowed >= 1,                 "Allowed mints exceeded.");
    
        holdersList[msg.sender]--;
        uint256 tokenId = _tokenIdCounter.current() + 1; //triple check and test counts
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function mintPresale() public payable whenNotPaused {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 100000000000000000; // 0.1 ETH
        require(msg.value == price,                  "Ether sent is not correct");
        checkSupply();
        safeMintPresale();
    }

    function mintPresaleAsh() public whenNotPaused {
        require(preSaleActive,                       "PreSale Not Active");
        uint256 price = 42 * 10 ** 18; // 42 Ash approx 0.1 ETH
        require(IERC20(ash).transferFrom(msg.sender, owner(), price), "$ASH transfer failed");
        checkSupply();
        safeMintPresale();
    }

    function safeMintPresale() internal {
        uint256 preSaleAllowed = greenList[msg.sender];
        require(preSaleAllowed >= 1,                 "Allowed mints exceeded.");
    
        greenList[msg.sender]--;
        uint256 tokenId = _tokenIdCounter.current() + 1; //triple check and test counts
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function purchase() public payable whenNotPaused nonReentrant {
        uint256 price = 100000000000000000; // 0.1 ETH
        require(publicSaleActive,                    "Public sale Not Active");
        require(msg.value == price,                  "Ether sent is not correct");
        checkSupply();
        safeMintPurchase();
    }

    function purchaseAsh() public whenNotPaused nonReentrant {
        require(publicSaleActive,                    "PreSale Not Active");
        uint256 price = 42 * 10 ** 18; // 42 Ash approx 0.1 ETH
        require(IERC20(ash).transferFrom(msg.sender, owner(), price), "$ASH transfer failed");        
        checkSupply();
        safeMintPurchase();
    }

    function safeMintPurchase() internal {
        uint256 tokenId = _tokenIdCounter.current() + 1; //triple check and test counts
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function reserveMint(address to, uint256 num) public onlyOwner {
        uint256 _supply = totalSupply();
        // Check available supply
        require(_supply + num < 112,                   "Exceeds maximum supply");
        for(uint256 i; i < num; i++){
            uint256 tokenId = _tokenIdCounter.current() + 1;
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function addToGreenList(address[] calldata users, uint256[] calldata quantity) external onlyOwner {
        require(users.length == quantity.length,     "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            greenList[users[i]] = quantity[i];
        }
    }

    function addToHoldersList(address[] calldata users, uint256[] calldata quantity) external onlyOwner {
        require(users.length == quantity.length,     "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            holdersList[users[i]] = quantity[i];
        }
    }

    function setColorIds(uint256[] calldata tokenIds, uint256[] calldata colorIds) external onlyOwner {
        require(tokenIds.length == colorIds.length,  "Must submit equal counts of tokenIds and colorIds");
        for(uint256 i = 0; i < tokenIds.length; i++){
            tokenColorIds[tokenIds[i]] = colorIds[i];
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}