// SPDX-License-Identifier: MIT
// Creator: https://twitter.com/xisk1699

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract ImmigrantNFT is Ownable, ERC721A, ReentrancyGuard {

    uint16 public immutable MAX_SUPPLY = 4000;
    uint16 public immutable MAX_SUPPLY_PRESALE = 700;
    address private immutable CEO_ADDRESS = 0x7432a6290a7b2c3e86fB7EfCc92FEb932Ab00237;
    string public baseTokenURI;

    struct SaleConfig {
        uint8 saleStage; // 0: PAUSED | 1: PRESALE | 2: PUBLIC SALE | 3: SOLDOUT
        uint64 presalePrice;
        uint64 publicSalePrice;
        uint8 maxMintAtOnce;
    }

    SaleConfig public saleConfig;

    constructor() ERC721A('The Immigrant', 'IMMIGRANT', 6, 4000) {
        saleConfig = SaleConfig(0, 0.015 ether, 0.025 ether, 6);
        baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmQd2sedReXKFt3bzG136rcp8MxvyMs2vKcNyQtYBVe4eo/";
    }

    // UPDATE SALECONFIG METHODS

    function setSaleStage(uint8 _saleStage) external onlyOwner {
        require(saleConfig.saleStage != 3, "Cannot update if already reached soldout stage.");
        saleConfig.saleStage = _saleStage;
    }

    // PRESALE MINT

    function presaleMint(uint8 _quantity) external payable nonReentrant {
        require(saleConfig.saleStage == 1, "Presale is not active.");
        require(_quantity <= saleConfig.maxMintAtOnce, "Max mint at onece exceeded.");
        require(totalSupply() + _quantity <= MAX_SUPPLY_PRESALE, "Mint would exceed max supply.");
        require(msg.value >= saleConfig.presalePrice * _quantity, "ETH value don't match.");

        _safeMint(msg.sender, _quantity);
        if (totalSupply() == MAX_SUPPLY_PRESALE) {
            saleConfig.saleStage = 0;
        }
    }

    // PUBLIC MINT 

    function publicMint(uint8 _quantity) external payable nonReentrant {
        require(saleConfig.saleStage == 2, "Public sale is not active.");
        require(_quantity <= saleConfig.maxMintAtOnce, "Max mint at onece exceeded.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Mint would exceed max supply.");
        require(msg.value >= saleConfig.publicSalePrice * _quantity, "ETH value don't match.");

        _safeMint(msg.sender, _quantity);
        if (totalSupply() == MAX_SUPPLY) {
            saleConfig.saleStage = 3;
        }
    }
    
    // METADATA URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenUri(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexisting token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId), ".json")) : "";
    }

    // WITHDRAW

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(CEO_ADDRESS).transfer(ethBalance);
    }
}