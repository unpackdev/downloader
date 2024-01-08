// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract EnglightenedOwlCouncil is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_OWLS = 4444;
    uint256 public constant PRICE = 0.025 ether;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant PRESALE_MAX_MINT = 3;
    uint256 public constant MAX_OWLS_MINT = 20;
    uint256 public constant RESERVED_OWLS = 50;
    address public constant ryanAddress = 0xb32D73ae0C6B07D016b91c5fCaA5714195eB71B3;
    address public constant rickyAddress = 0x54FFEDEc1a91A58799eB11914ec0f1B20579A014;
    address public constant technoAddress = 0xa7ecb827709E09cC95Aa4c1AED836A8DF861Eae6;


    uint256 public reservedClaimed;

    uint256 public numOwlsMinted;

    string public baseTokenURI = "ipfs://QmVjBhtFDV9QqfcuyopzgANzq6q53X7k4zkcmwkWU7MKFP/";

    bool public publicSaleStarted;
    bool public presaleStarted = true;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfOwls);
    event PublicSaleMint(address minter, uint256 amountOfOwls);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

    constructor() ERC721("Englightened Owl Council", "EOC") {
    }

    function claimReserved(address[] calldata addresses) external onlyOwner {
        require(reservedClaimed != RESERVED_OWLS, "Already have claimed all reserved owls");
        require(reservedClaimed + addresses.length <= RESERVED_OWLS, "Minting would exceed max reserved owls");
        require(totalSupply() + addresses.length <= MAX_OWLS, "Minting would exceed max supply");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], numOwlsMinted +1 + i);
        }
        
        numOwlsMinted += addresses.length;
        reservedClaimed += addresses.length;
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

    function mintPresale(uint256 amountOfOwls) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not eligible for the presale");
        require(totalSupply() < MAX_OWLS, "All tokens have been minted");
        require(amountOfOwls <= PRESALE_MAX_MINT, "Cannot purchase this many tokens during presale");
        require(totalSupply() + amountOfOwls <= MAX_OWLS - (RESERVED_OWLS - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimed[msg.sender] + amountOfOwls <= PRESALE_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfOwls > 0, "Must mint at least one owl");
        require(PRICE * amountOfOwls == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfOwls; i++) {
            uint256 tokenId = numOwlsMinted + 1;

            numOwlsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfOwls);
    }

    function mint(uint256 amountOfOwls) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_OWLS, "All tokens have been minted");
        require(amountOfOwls <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + amountOfOwls <= MAX_OWLS - (RESERVED_OWLS - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimed[msg.sender] + amountOfOwls <= MAX_OWLS_MINT, "Purchase exceeds max allowed per address");
        require(amountOfOwls > 0, "Must mint at least one owl");
        require(PRICE * amountOfOwls == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfOwls; i++) {
            uint256 tokenId = numOwlsMinted + 1;

            numOwlsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfOwls);
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

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        
        _widthdraw(ryanAddress, (balance * 1/3));
        _widthdraw(rickyAddress, (balance * 1/3));

        _widthdraw(technoAddress, address(this).balance);
    }

}