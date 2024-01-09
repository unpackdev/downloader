//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";

contract SimpQueenDao is ERC721, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string public baseURI;

    uint256 public maxTx = 3;
    uint256 public maxSupply = 5000;
    uint256 public presaleSupply = 3000;
    uint256 public price = 0.02 ether;

    uint256 public presaleTime = 1642518300;
    uint256 public presaleClose = 1642521000;
    uint256 public mainsaleTime = 1643104800;
    Counters.Counter private _tokenIdTracker;

    mapping(address => bool) public presaleWallets;
    mapping(address => uint256) public presaleWalletLimits;
    mapping(address => uint256) public mainsaleWalletLimits;

    // payees and shares should of equal length
    constructor(
        string memory _initBaseURI,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721("SimpQueenDAO", "SQDAO") PaymentSplitter(_payees, _shares) {
        baseURI = _initBaseURI;
    }

    //Checks for main and pre sale open to mint
    modifier isMainsaleOpen() {
        require(block.timestamp >= mainsaleTime, "Mainsale closed!");
        _;
    }
    modifier isPresaleOpen() {
        require(
            block.timestamp >= presaleTime && block.timestamp <= presaleClose,
            "Presale closed!"
        );
        _;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    // Mint for Mainsale
    function mainSale(uint256 _mintTotal) public payable isMainsaleOpen {
        uint256 totalMinted = _mintTotal + mainsaleWalletLimits[msg.sender];

        require(_mintTotal <= maxTx, "Mint Amount Incorrect");

        require(
            msg.value >= price.mul(_mintTotal),
            "Minting Costs 0.02 Ether Each!"
        );
        require(totalToken() <= maxSupply, "SOLD OUT!");
        require(totalMinted <= maxTx, "You'll pass mint limit!");

        for (uint256 i = 0; i < _mintTotal; i++) {
            mainsaleWalletLimits[msg.sender]++;
            _tokenIdTracker.increment();
            require(totalToken() <= maxSupply, "SOLD OUT!");
            _safeMint(msg.sender, totalToken());
        }
    }

    // Mint for Presale
    function preSale(uint256 _mintTotal) public payable isPresaleOpen {
        uint256 totalMinted = _mintTotal + presaleWalletLimits[msg.sender];

        require(presaleWallets[msg.sender] == true, "You aren't whitelisted!");
        require(_mintTotal <= maxTx, "Mint Amount Incorrect");
        require(
            msg.value >= price.mul(_mintTotal),
            "Minting Costs 0.02 Ether Each!"
        );
        require(totalToken() <= presaleSupply, "SOLD OUT!");
        require(totalMinted <= maxTx, "You'll pass mint limit!");

        for (uint256 i = 0; i < _mintTotal; i++) {
            presaleWalletLimits[msg.sender]++;
            _tokenIdTracker.increment();
            require(totalToken() <= presaleSupply, "SOLD OUT!");
            _safeMint(msg.sender, totalToken());
        }
    }

    // Add new address(es) to Whitelist
    function addWhiteList(address[] memory _whiteListedAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _whiteListedAddresses.length; i++) {
            presaleWallets[_whiteListedAddresses[i]] = true;
        }
    }

    // Checks if address is whitelisted
    function isAddressWhitelisted(address _whitelist)
        public
        view
        returns (bool)
    {
        return presaleWallets[_whitelist];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    // Change URI, Price, MaxTx, etc.  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxTx(uint256 _newMax) external onlyOwner {
        maxTx = _newMax;
    }

    function setPresaleStart(uint256 _presaleStart) external onlyOwner {
        presaleTime = _presaleStart;
    }

    function setPresaleClose(uint256 _presaleClose) external onlyOwner {
        presaleClose = _presaleClose;
    }

    function setMainSaleStart(uint256 _mainsaleStart) external onlyOwner {
        mainsaleTime = _mainsaleStart;
    }
}
