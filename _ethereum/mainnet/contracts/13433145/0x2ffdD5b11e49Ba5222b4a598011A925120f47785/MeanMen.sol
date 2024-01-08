// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract MeanMen is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFTS = 11111;
    uint256 public constant PRICE1NFT = 0.07 ether; // Price per NFT if 1-4 NFTs are minted 
    uint256 public constant PRICE5NFTS = 0.065 ether; // Price per NFT if 5 - 9 NFTS are minted
    uint256 public constant PRICE10NFTS = 0.06 ether; // Price per NFT if 10 + NFTS are minted
    uint256 public constant MAX_PER_MINT = 20;
    uint256 public constant PRESALE_MAX_MINT = 20;
    uint256 public constant RESERVED_NFTS = 611;
    address public constant teamAddress = 0xB4167b137456Bf44e53ce141C4bE4b204D6f2d72;
    address public constant advisorAddress = 0xEbCEe6204eeEEf21e406C0A75734E70f342914e0;
    address public constant devAddress = 0xADDaF99990b665D8553f08653966fa8995Cc1209;

    uint256 public reservedClaimed;

    uint256 public numNftsMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfNfts);
    event PublicSaleMint(address minter, uint256 amountOfNfts);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale is not open yet");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale is not open yet");
        _;
    }

    constructor(string memory baseURI) ERC721("Mean Men", "MM") {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed != RESERVED_NFTS, "You have already claimed all reserved nfts");
        require(reservedClaimed + amount <= RESERVED_NFTS, "Mint exceeds max reserved nfts");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(totalSupply() + amount <= MAX_NFTS, "Mint exceeds max supply");

        uint256 _nextTokenId = numNftsMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numNftsMinted += amount;
        reservedClaimed += amount;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }
    
    function calculatePrice(uint256 amountOfNfts) public pure returns (uint256) {
        uint256 price;
        if (amountOfNfts > 0 && amountOfNfts < 5) price = PRICE1NFT * amountOfNfts;
        else if (amountOfNfts > 4 && amountOfNfts < 10) price = PRICE5NFTS * amountOfNfts;
        else if (amountOfNfts > 9) price = PRICE10NFTS * amountOfNfts;
        
        return price;
    }
    

    function mintPresale(uint256 amountOfNfts) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not whitelisted for the presale");
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds presale limit");
        require(totalSupply() + amountOfNfts <= MAX_NFTS, "Mint exceeds max supply");
        require(_totalClaimed[msg.sender] + amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(calculatePrice(amountOfNfts) == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfNfts; i++) {
            uint256 tokenId = numNftsMinted + 1;

            numNftsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfNfts);
    }

    function mint(uint256 amountOfNfts) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(amountOfNfts <= MAX_PER_MINT, "Amount exceeds NFTs per transaction");
        require(totalSupply() + amountOfNfts <= MAX_NFTS, "Mint exceeds max supply");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(calculatePrice(amountOfNfts) == msg.value, "Amount of ETH is incorrect");

        for (uint256 i = 0; i < amountOfNfts; i++) {
            uint256 tokenId = numNftsMinted + 1;

            numNftsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfNfts);
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(devAddress, ((balance * 15) / 100));
        _widthdraw(advisorAddress, ((balance * 5) / 100));
        _widthdraw(teamAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}