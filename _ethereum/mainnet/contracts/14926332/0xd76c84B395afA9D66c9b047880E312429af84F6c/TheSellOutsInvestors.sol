//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721APreapproved.sol";
import "./IERC2981.sol";
import "./PaymentSplitter.sol";

contract TheSellOutsInvestors is ERC721APreapproved, IERC2981, PaymentSplitter {
    enum SaleState { CLOSED, OPEN }

    struct SaleConfig {
        SaleState SALE_STATUS;
        uint16 ROYALTY_BPS;
        uint128 PRICE;
    }

    struct Addresses {
        address treasury;
        address openSeaProxyRegistryAddress;
        address looksRareTransferManagerAddress;
    }

    uint8 private constant MAX_SUPPLY = 10;
    
    SaleConfig private _config;
    Addresses private _addresses;
    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory payees,
        uint256[] memory shares,
        SaleConfig memory saleConfig,
        Addresses memory addresses,
        string memory baseTokenURI
    ) 
        ERC721APreapproved(name, symbol, addresses.openSeaProxyRegistryAddress, addresses.looksRareTransferManagerAddress) 
        PaymentSplitter(payees, shares) 
    {
        _config = saleConfig;
        _addresses = addresses;
        _baseTokenURI = baseTokenURI;
    }

    function mintInvestor(address wallet) external payable {
        require(_config.SALE_STATUS != SaleState.CLOSED, "SALE_CLOSED");
        require(msg.value == _config.PRICE, "INCORRECT_FUNDS");
        require(_totalMinted() < MAX_SUPPLY, "MAX_SUPPLY_ALREADY_MINTED");

        _safeMint(wallet, 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NONEXISTENT_TOKEN");

        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
 
    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) external view override returns (address, uint256) {
        return (_addresses.treasury, (_salePrice * _config.ROYALTY_BPS / 10000));
    }
    
    function saleStatus() external view returns (SaleState) {
        return _config.SALE_STATUS;
    }

    function setSaleConfig(SaleConfig calldata config) external onlyOwner {
        _config = config;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC721A) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }
}
