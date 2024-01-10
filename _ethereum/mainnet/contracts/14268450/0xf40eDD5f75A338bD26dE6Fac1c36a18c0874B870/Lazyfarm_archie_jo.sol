// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
// import "./ReentrancyGuard.sol";
// import "./Strings.sol";

import "./ERC721A.sol";

/*
 * @title ERC-721 NFT for Lazyfarm NFT - Archie & Jo
 * @author acorn421
 */
contract LazyfarmNFT is Ownable, ERC721A {
    // Max supply
    uint256 public constant MAX_SUPPLY = 10000;

    // Sale configure
    uint256 public currentSupplyLimit = 1000;
    uint256 public maxPerWallet = 20;
    // Sale price
    uint256 public price = 0.03 ether;
    // Sale timestamps
    uint256 public preStartTimestamp = 1647090000;      // Sat Mar 12 2022 13:00:00 GMT+0000
    uint256 public publicStartTimestamp = 1647176400;   // Sun Mar 13 2022 13:00:00 GMT+0000

    // Sale paused?
    bool public paused = false;

    // Metadata URI
    string public baseURI = "https://metadata.lazyfarmnft.com/archie_jo/";

    // Track mints
    mapping(address => uint256) private walletMints;
    mapping(address => uint8) private allowList;
    
    constructor() ERC721A("Lazyfarm NFT - Archie & Jo", "LAFA") {}

    // function mint(uint256 quantity) private {
    //     uint256 supply = totalSupply();
    //     walletMints[msg.sender] += quantity;
    //     for (uint256 i = 0; i < quantity; i++) {
    //         uint256 newTokenId = supply + 1;
    //         _safeMint(msg.sender, newTokenId);
    //     }
    // }

    function sale(address toAddress, uint256 quantity) private {
        walletMints[toAddress] += quantity;
        _safeMint(toAddress, quantity);
        currentSupplyLimit -= quantity;
    }

    function defaultMintingRules(uint256 quantity) private view {
        require(totalSupply() < MAX_SUPPLY, "All NFTs are sold out");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Exceeds MAX_SUPPLY. Try it with lower quantity"
        );
    }

    function saleMintingRules(
        uint256 value,
        uint256 quantity
    ) private view {
        defaultMintingRules(quantity);
        require(0 < currentSupplyLimit, "All NFTs of current sale phase sold out.");
        require(
            quantity <= currentSupplyLimit,
            "Exceeds supply of current sale phase. Try it with lower quantity"
        );
        require(!paused, "Sale paused");
        require(value == quantity * price, "Wrong ether price");
        require(
            walletMints[msg.sender] + quantity <= maxPerWallet,
            "Exceeds max per wallet"
        );
    }

    function mintPre(uint256 quantity) public payable {
        require(
            block.timestamp >= preStartTimestamp,
            "Pre sale has not started yet"
        );
        require(quantity <= allowList[msg.sender], "Exceeded max available to allowlist purchase");

        saleMintingRules(msg.value, quantity);
        sale(msg.sender, quantity);
        allowList[msg.sender] -= uint8(quantity);
    }

    function mintPublic(uint256 quantity) public payable {
        require(
            block.timestamp >= publicStartTimestamp,
            "Public sale has not started yet"
        );
        saleMintingRules(msg.value, quantity);
        sale(msg.sender, quantity);
    }

    function mintDev(uint256 quantity) public onlyOwner {
        defaultMintingRules(quantity);
        _safeMint(msg.sender, quantity);
    }

    function giveAway(address toAddress, uint256 quantity) external onlyOwner {
        defaultMintingRules(quantity);
        _safeMint(toAddress, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function setPriceInWei(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setCurrentSupplyLimit(uint256 _currentSupplyLimit) external onlyOwner {
        currentSupplyLimit = _currentSupplyLimit;
    }

    function setPreStartTimestamp(uint256 _preStartTimestamp) external onlyOwner {
        preStartTimestamp = _preStartTimestamp;
    }

    function setPublicStartTimestamp(uint256 _publicStartTimestamp) external onlyOwner {
        publicStartTimestamp = _publicStartTimestamp;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
