// SPDX-License-Identifier: UNLICENSED
// Latest known version with no issues
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// RentalzLambo (Developed by Daniel Kantor)
// Rentalz.io kicks off its first collection of 3,333 unique hand-drawn Lambo NFTs that will grant you membership access 
// to exotic sports cars and more. Future projects will include real estate, yachts, and other luxury perks. 
// Join our community for the latest updates https://discord.gg/rentalzio

pragma solidity ^0.8.4;

contract RentalzLambo is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    string private baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.22 ether;
    uint256 public preSaleCost = 0.2 ether;
    uint256 public keysCost = 0.18 ether;
    uint256 public maxSupply = 3333;
    uint256 public maxMintAmount = 5;
    uint256 public nftPerAddressLimit = 150;
    uint256 public nftPerAddressLimitPresale = 5;

    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    bool public paused = false;
    bool public revealed = false;

    // KEYS Contract
    address private constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    // Locked KEYS Contract
    address private constant LOCKED_KEYS = 0x08DC692FE528fFEcF675Ab3f76981553e060Fd8A;

    // 8,888 KEYS needed for discount
    uint256 public minKeysNeededForDiscount = 8888000000000;

    // Friday, January 21, 2022 6:30:00 PM GMT-05:00
    uint256 public preSaleDate = 1642807800;

    // Saturday, January 22, 2022 6:30:00 PM GMT-05:00
    uint256 public publicSaleDate = 1642894200;

    // Monday, January 24, 2022 6:30:00 PM GMT-05:00
    uint256 public revealDate = 1643067000;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    //MODIFIERS
    modifier notPaused() {
        require(!paused, "the contract is paused");
        _;
    }

    modifier saleStarted() {
        require(block.timestamp >= preSaleDate, "Sale has not started yet");
        _;
    }

    modifier minimumMintAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _;
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  MINT FUNCTION  ///////////////////////////
    /////////////////////////////////////////////////////////////////

    function mint(uint256 _mintAmount) external payable notPaused saleStarted minimumMintAmount(_mintAmount) {
        // Get some data
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        uint256 supply = totalSupply();

        // Do some validations based on what state of the sale we are in
        block.timestamp < publicSaleDate
            ? preSaleValidations(ownerMintedCount, _mintAmount)
            : publicSaleValidations(ownerMintedCount, _mintAmount);

        // Check if max NFT limit has been reached
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        // Safely mint those Lambos
        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  EXTERNAL FUNCTIONS  //////////////////////
    /////////////////////////////////////////////////////////////////

    // Receive function in case someone wants to donate some ETH to the contract
    receive() external payable {}

    // Check what tokenIds are owned by a given wallets
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Gives the tokenURI for a given tokenId
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();

        // If not revealed, show non-revealed image
        if (!revealed) {
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI)) : "";
        }
        // else, show revealed image
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function getCurrentCost() external view returns (uint256) {
        return cost;
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return whitelistedAddresses[_user];
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  ONLY OWNER FUNCTIONS  ////////////////////
    /////////////////////////////////////////////////////////////////

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    // Will be used to gift the team 
    function gift(uint256 _mintAmount, address destination) external onlyOwner {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[destination]++;
            _safeMint(destination, supply + i);
        }
    }

    function whitelistUsers(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Withdraw not successful");
    }

    function flipRevealed() external onlyOwner {
        revealed = !revealed;
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  SETTER FUNCTIONS  ////////////////////////
    /////////////////////////////////////////////////////////////////

    function setNftPerAddressLimit(uint256 _limit) external onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setNftPerAddressPresaleLimit(uint256 _limit) external onlyOwner {
        nftPerAddressLimitPresale = _limit;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setPreSaleCost(uint256 _newCost) external onlyOwner {
        preSaleCost = _newCost;
    }

    function setKeysCost(uint256 _newCost) external onlyOwner {
        keysCost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPublicSaleDate(uint256 _publicSaleDate) external onlyOwner {
        publicSaleDate = _publicSaleDate;
    }

    function setPreSaleDate(uint256 _preSaleDate) external onlyOwner {
        preSaleDate = _preSaleDate;
    }

    function setRevealDate(uint256 _revealDate) external onlyOwner {
        revealDate = _revealDate;
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  INTERNAL FUNCTIONS  //////////////////////
    /////////////////////////////////////////////////////////////////

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function publicSaleValidations(uint256 _ownerMintedCount, uint256 _mintAmount) internal {
        uint256 actualCost;

        discountForKeysHolders() ? actualCost = keysCost : actualCost = cost;
        
        require(_ownerMintedCount + _mintAmount <= nftPerAddressLimit, 
        "max NFT per address exceeded");

        require(msg.value >= actualCost * _mintAmount, 
        "insufficient funds");

        require(_mintAmount <= maxMintAmount, 
        "max mint amount per transaction exceeded");
    }

    function preSaleValidations(uint256 _ownerMintedCount, uint256 _mintAmount) internal {
        uint256 actualCost;

        discountForKeysHolders() ? actualCost = keysCost : actualCost = preSaleCost;
        
        require(isWhitelisted(msg.sender), 
        "User is NOT whitelisted");
        require(_ownerMintedCount + _mintAmount <= nftPerAddressLimitPresale,
         "max NFT per address exceeded for presale");
        require(msg.value >= actualCost * _mintAmount, 
        "insufficient funds");
        require(_mintAmount <= maxMintAmount, 
        "max mint amount per transaction exceeded");
    }

    function discountForKeysHolders() internal view returns (bool) {
        uint256 amountOfKeysOwned = IERC20(KEYS).balanceOf(msg.sender);
        uint256 amountOfLockedKeysOwned = IERC20(LOCKED_KEYS).balanceOf(msg.sender);
        uint256 totalKeysOwned = amountOfKeysOwned.add(amountOfLockedKeysOwned);

        return (totalKeysOwned >= minKeysNeededForDiscount);
    }
}
