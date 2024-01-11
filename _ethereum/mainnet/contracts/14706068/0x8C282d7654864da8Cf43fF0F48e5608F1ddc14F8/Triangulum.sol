//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721APreapproved.sol";
import "./draft-EIP712.sol";
import "./IERC2981.sol";
import "./PaymentSplitter.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract Triangulum is ERC721APreapproved, EIP712, IERC2981, PaymentSplitter {
    enum SaleState { CLOSED, OPEN }
    enum SaleType { PUBLIC, ALLOWLIST, FARMOORE }
    struct MintKey { SaleType saleType; uint8 quantity; address wallet; }

    struct SaleConfig {
        SaleState SALE_STATUS;
        uint8 RESERVED;
        uint8 MAX_PER_MINT;
        uint16 ROYALTY_BPS;
        uint128 PUBLIC_PRICE;
        uint128 ALLOWLIST_PRICE;
        uint128 FARMOORE_PRICE;
    }

    struct Addresses {
        address signer;
        address treasury;
        address openSeaProxyRegistryAddress;
        address looksRareTransferManagerAddress;
    }

    bytes32 private constant MINTKEY_TYPE_HASH = keccak256("MintKey(uint8 saleType,uint8 quantity,address wallet)");
    uint16 private constant MAX_SUPPLY = 2000;
    
    SaleConfig private _config;
    Addresses private _addresses;
    string private _baseTokenURI;

    mapping(address => bool) private _walletsClaimed;

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
        EIP712(name, "1") 
        PaymentSplitter(payees, shares) 
    {
        _config = saleConfig;
        _addresses = addresses;
        _baseTokenURI = baseTokenURI;
    }

    modifier saleIsOpen() {
        require(_config.SALE_STATUS != SaleState.CLOSED, "SALE_CLOSED");
        _;
    }

    modifier doesNotExceedMaxSupply(uint8 amount) {
        require(_currentIndex + amount <= MAX_SUPPLY, "QTY_EXCEEDS_MAX_SUPPLY");
        _;
    }

    function mintNFTs(bytes calldata signature, MintKey calldata mintKey) external payable saleIsOpen doesNotExceedMaxSupply(mintKey.quantity) {
        require(mintKey.quantity > 0 && mintKey.quantity <= _config.MAX_PER_MINT, "INCORRECT_QUANTITY");
        require(msg.value == getPrice(mintKey.saleType) * mintKey.quantity, "INCORRECT_FUNDS");

        if (mintKey.saleType != SaleType.PUBLIC) {
            require(verify(signature, mintKey), "INVALID_SIGNATURE");
        }

        if (mintKey.saleType == SaleType.FARMOORE) {
            require(mintKey.quantity == 1, "ONLY_ONE_FREE_ALLOWED");
            require(_walletsClaimed[mintKey.wallet] == false, "ALREADY_CLAIMED");
            _walletsClaimed[mintKey.wallet] = true;
        }

        _safeMint(mintKey.wallet, mintKey.quantity);
    }

    function reserve(uint8 amount) external onlyOwner doesNotExceedMaxSupply(amount) {
        require(amount > 0 && amount <= _config.RESERVED, "RESERVE_EXCEEDED");

        _safeMint(msg.sender, amount);
        _config.RESERVED -= amount;
    }
    
    function getPrice(SaleType saleType) public view returns (uint128) {
        if (saleType == SaleType.ALLOWLIST)
            return _config.ALLOWLIST_PRICE;

        if (saleType == SaleType.FARMOORE)
            return _config.FARMOORE_PRICE;

        return _config.PUBLIC_PRICE;
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
    
    function isFarmooreMintClaimed(address wallet) external view returns (bool) {
        return _walletsClaimed[wallet];
    }

    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) external view override returns (address, uint256) {
        return (_addresses.treasury, (_salePrice * _config.ROYALTY_BPS / 10000));
    }

    function saleStatus() external view returns (SaleState) {
        return _config.SALE_STATUS;
    }

    function setSaleConfig(SaleConfig calldata config) external onlyOwner {
        uint8 oldReserve = _config.RESERVED; // don't allow reserve override
        _config = config;
        _config.RESERVED = oldReserve;
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC721A) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    function verify(bytes calldata signature, MintKey calldata mintKey) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINTKEY_TYPE_HASH,
                    mintKey.saleType,
                    mintKey.quantity,
                    mintKey.wallet
                )
            )
        );

        return ECDSA.recover(digest, signature) == _addresses.signer;
    }
}
