// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Gnomes is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFTS = 8888;
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant PRESALE_MAX_MINT = 20;
    uint256 public constant MAX_NFTS_MINT = 50;
    uint256 public constant RESERVED_NFTS = 100;
    address public constant team1Address = 0x81a006cF4A0E0B4dD646c5F77D46913fA89338B4;
    address public constant team2Address = 0x20Bc36a766690c70aBE46aE70026c4cD9C409246;
    address public constant team3Address = 0xe8e2dfd4042b9Ab92cCD5F6814E34F6C8a91A661;
    address public constant team4Address = 0x3b3456a3548A871bE8bB15EdCbc0A08Be9263ea7;
    address public constant team5Address = 0xa0410b9d391e528d3fb09589F3aB493263D22e2D;
    address public constant team6Address = 0xe73076E51102998be816A8Ead81Fd8764dcE66d2;    
    address public constant devAddress = 0xADDaF99990b665D8553f08653966fa8995Cc1209;
    address public constant founderAddress = 0xc03b6c8c5565f4E5c8f78d6C0De3472a6b30b3C7;

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

    constructor(string memory baseURI) ERC721("Nutty Gnomes", "NG") {
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
        _widthdraw(team1Address, ((balance * 1) / 100));
        _widthdraw(team2Address, ((balance * 3) / 100));
        _widthdraw(team3Address, ((balance * 3) / 100));
        _widthdraw(team4Address, ((balance * 7) / 100));
        _widthdraw(team5Address, ((balance * 7) / 100));
        _widthdraw(team6Address, ((balance * 13) / 100));
        _widthdraw(devAddress, ((balance * 20) / 100));
        _widthdraw(founderAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}