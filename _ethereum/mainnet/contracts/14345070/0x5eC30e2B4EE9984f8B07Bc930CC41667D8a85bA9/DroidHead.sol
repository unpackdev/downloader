// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Droidheads is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFTS = 2500;
    uint256 public constant PRICE = 0.1337 ether;
    uint256 public constant MAX_PER_MINT = 5;
    uint256 public constant PRESALE_MAX_MINT = 1;
    uint256 public constant MAX_NFTS_MINT = 50;
    uint256 public constant RESERVED_NFTS = 50;
    address public constant team1Address = 0xe354d2b1A2D958df199a06eDf82aCbB5C5557826;
    address public constant team2Address = 0x034B626906BedA0d9ac11826B9840a55e5755F2F;
    address public constant team3Address = 0xE62fBF11F772CA859700B1Fe7bc0bF1deD90b958;
    address public constant team4Address = 0x233e50d587024E306aed5f4c5283C71abc749aD8;
    address public constant team5Address = 0x350b97102f9670652C3e7427480eCF76DE090029;
    address public constant team6Address = 0x179E47D3b5d57344AB3E96CCC3086875709671BA;
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
        require(presaleStarted, "Presale is not open");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale is not open");
        _;
    }

    constructor(string memory baseURI) ERC721("droidheads: origin", "DROID") {
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

    function mintPresale(uint256 amountOfNfts) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not whitelisted for the presale");
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds presale limit");
        require(totalSupply() + amountOfNfts <= MAX_NFTS, "Mint exceeds max supply");
        require(_totalClaimed[msg.sender] + amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(PRICE * amountOfNfts == msg.value, "ETH amount is incorrect");

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
        require(_totalClaimed[msg.sender] + amountOfNfts <= MAX_NFTS_MINT, "Amount exceeds max NFTs per wallet");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(PRICE * amountOfNfts == msg.value, "Amount of ETH is incorrect");

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
        _widthdraw(devAddress, ((balance * 10) / 100));
        _widthdraw(team1Address, ((balance * 5) / 100));
        _widthdraw(team2Address, ((balance * 8) / 100));
        _widthdraw(team3Address, ((balance * 8) / 100));
        _widthdraw(team4Address, ((balance * 8) / 100));
        _widthdraw(team5Address, ((balance * 1) / 100));
        _widthdraw(team6Address, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}