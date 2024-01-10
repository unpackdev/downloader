//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./ERC721A.sol";

/**
 @title Artwork NFT by Yayoi Kusama
 @author Japan NFT Culture Association (https://www.jnca.io)
 */
contract YayoiKusamaHandbagArtwork is ERC721A, EIP712, Ownable {
    uint16 private constant MAX_SUPPLY = 7000;

    uint16 private constant WHITELIST_MAX_SUPPLY = 3000;

    uint8 private constant BATCH_MINT_SIZE = 5;

    string private _contractURI;

    string private _tokenBaseURI;

    address payable private _fundReceiver;

    mapping(address => uint8) public whitelistAlreadyMinted;

    struct SaleInfo {
        bool isPublic;
        uint104 publicPrice;
        bool isWhitelist;
        uint104 whitelistPrice;
        uint16 whitelistSupply;
    }
    SaleInfo public saleInfo;

    // voucher for user to redeem
    struct NFTVoucher {
        address redeemer; // specify user to redeem this voucher
    }

    /// @dev Setup contractURI, initial base URI, ERC721
    constructor(
        string memory initContractURI,
        string memory initBaseURI,
        address payable receiver,
        uint104 publicPrice,
        uint104 whitelistPrice
    )
        ERC721A(
            "Yayoi Kusama Handbag Artwork",
            "YKHA",
            BATCH_MINT_SIZE,
            MAX_SUPPLY
        )
        EIP712("YKHA", "1")
    {
        _contractURI = initContractURI;
        _tokenBaseURI = initBaseURI;
        _fundReceiver = receiver;
        saleInfo.isPublic = false;
        saleInfo.publicPrice = publicPrice;
        saleInfo.isWhitelist = false;
        saleInfo.whitelistPrice = whitelistPrice;
        saleInfo.whitelistSupply = 0;
    }

    /// @notice Contract info read by marketplace
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Mint certain amount of tokens
    function mint(uint256 amount) external payable {
        require(saleInfo.isPublic, "not in public sale");
        require(totalSupply() + amount <= MAX_SUPPLY, "exceed max supply");
        require(amount * saleInfo.publicPrice == msg.value, "payment error");
        _safeMint(_msgSender(), amount);
    }

    /// @notice Mint for whitelist (EIP712)
    function whitelistMint(bytes calldata signature, uint8 amount)
        external
        payable
    {
        _verify(signature);
        require(saleInfo.isWhitelist, "not in whitelist sale");
        require(totalSupply() + amount <= MAX_SUPPLY, "exceed max supply");
        require(
            saleInfo.whitelistSupply + amount <= WHITELIST_MAX_SUPPLY,
            "exceed whitelist max supply"
        );
        saleInfo.whitelistSupply += amount;
        require(
            whitelistAlreadyMinted[_msgSender()] + amount <= BATCH_MINT_SIZE,
            "exceed whitelist quota"
        );
        whitelistAlreadyMinted[_msgSender()] += amount;
        require(amount * saleInfo.whitelistPrice == msg.value, "payment error");
        _safeMint(_msgSender(), amount);
    }

    /// @dev Withdraw fund from contract to receiver
    function withdraw() external {
        Address.sendValue(_fundReceiver, address(this).balance);
    }

    /// @dev Change base URI to reveal NFT
    function setBaseURI(string calldata newBaseURI)
        external
        onlyOwner
    {
        _tokenBaseURI = newBaseURI;
    }

    /// @dev Flip public sale state
    function flipPublicSale() external onlyOwner {
        saleInfo.isPublic = !saleInfo.isPublic;
    }

    /// @dev Flip whitelist sale state
    function flipWhitelistSale() external onlyOwner {
        saleInfo.isWhitelist = !saleInfo.isWhitelist;
    }

    /// @dev Update sale info (without changing whitelist supply)
    function updateSaleInfo(SaleInfo calldata newSaleInfo) external onlyOwner {
        saleInfo.isPublic = newSaleInfo.isPublic;
        saleInfo.publicPrice = newSaleInfo.publicPrice;
        saleInfo.isWhitelist = newSaleInfo.isWhitelist;
        saleInfo.whitelistPrice = newSaleInfo.whitelistPrice;
    }

    /// @dev Override ERC721._baseURI
    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /// @dev Verify voucher
    function _verify(bytes calldata signature) private view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("NFTVoucher(address redeemer)"),
                    _msgSender()
                )
            )
        );
        require(
            owner() == ECDSA.recover(digest, signature),
            "invalid or unauthorized"
        );
    }
}
