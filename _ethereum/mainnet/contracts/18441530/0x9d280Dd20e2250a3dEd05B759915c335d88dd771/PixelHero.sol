// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./IERC2981.sol";


struct NftConfig {
    address signer;
    string baseUrl;
    uint256 maxSupply;
    address payable salesWallet;
}

struct PublicMintConfig {
    bool open;
    uint256 ethPrice;
    uint256 maxPerWallet;
}

struct MintCoupon {
    // IDs are used against reply attacks
    uint128 id;
    // how much does one NFT cost
    uint256 ethPrice;
    // maximum amount of tokens to mint
    uint256 maxAmount;
    // earliest time when the request is valid
    uint256 validFrom;
    // how long will the request be valid (deadline)
    uint256 validTo;
    // signature for the request
    bytes signature;
}

contract PixelHero is
    ERC721,
    ERC721Burnable,
    ERC721Enumerable,
    IERC2981,
    Ownable,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    using Address for address payable;
    using Strings for uint256;

    bytes32 public immutable mintSalt = keccak256("mint");

    NftConfig public config;
    PublicMintConfig internal _publicMintConfig;

    // Royalties. Default is 5% (0.05)
    uint96 public royaltyFee = 500;
    uint96 public immutable royaltyFeeDenominator = 10000;

    // the number of tokens minted per request ID.
    mapping(uint128 => uint256) public mintedPerCoupon;
    // the number of tokens minted per address in the public sale.
    mapping(address => uint256) public mintedPerAddress;
    uint256 public minted = 0;

    constructor(
        NftConfig memory _config,
        PublicMintConfig memory _mintConfig
    ) ERC721("PixelHero", "PixelHero") {
        config = _config;
        _publicMintConfig = _mintConfig;
    }

    // ADMIN STUFF

    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0));
        config.signer = _signer;
    }

    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        config.baseUrl = _baseUrl;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        require(_maxPerWallet > 0);
        _publicMintConfig.maxPerWallet = _maxPerWallet;
    }

    function setEthPrice(uint256 _ethPrice) public onlyOwner {
        _publicMintConfig.ethPrice = _ethPrice;
    }

    function setSalesWallet(address _salesWallet) public onlyOwner {
        require(_salesWallet != address(0));
        config.salesWallet = payable(_salesWallet);
    }

    function setPublicMintOpen(bool _isOpen) public onlyOwner {
        _publicMintConfig.open = _isOpen;
    }

    function setRoyaltyFee(uint96 _royaltyFee) public onlyOwner {
        require(_royaltyFee <= royaltyFeeDenominator);
        royaltyFee = _royaltyFee;
    }

    // ROYALTY INFO
    function royaltyInfo(uint256 /*tokenId*/, uint256 salePrice) public view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * royaltyFee) / royaltyFeeDenominator;
        return (config.salesWallet, royaltyAmount);
    }

    // PUBLIC / MINTING STUFF

    function publicMintConfig() public view returns (PublicMintConfig memory) {
        return _publicMintConfig;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _requireMinted(_tokenId);

        return
            string(
                abi.encodePacked(config.baseUrl, _tokenId.toString(), ".json")
            );
    }

    function validateCouponSignature(
        MintCoupon calldata _coupon
    ) internal view {
        bytes32 hashed = keccak256(
            abi.encode(
                mintSalt,
                block.chainid,
                address(this),
                _msgSender(),
                _coupon.id,
                _coupon.validFrom,
                _coupon.validTo,
                _coupon.maxAmount,
                _coupon.ethPrice
            )
        );

        (address _signedBy,) = hashed.tryRecover(_coupon.signature);
        require(_signedBy == config.signer, "Signature mismatch");
    }

    function validateCouponData(MintCoupon calldata _coupon) internal view {
        require(_coupon.validFrom <= block.timestamp, "Request is not valid yet");
        require(_coupon.validTo >= block.timestamp, "Request is not valid anymore");
    }

    function chargeEth(uint256 cost) internal {
        if (cost > 0) {
            require(msg.value >= cost, "Not enough ETH");
            uint256 remaining = msg.value - cost;
            config.salesWallet.sendValue(cost);
            if (remaining > 0) {
                payable(_msgSender()).sendValue(remaining);
            }
        }
    }

    function checkSupplyAvailable(uint256 amount) internal view {
        require(
            minted + amount <= config.maxSupply,
            "Not enough tokens left to mint"
        );
    }

    function mint(address to, uint256 amount) internal {
        uint256 i = minted;
        minted += amount;
        for (; i < minted; i++) {
            _mint(to, i);
        }
    }

    function mintPublic(uint256 amount) public payable nonReentrant {
        require(_publicMintConfig.open, "Minting is not open");
        checkSupplyAvailable(amount);
        mintedPerAddress[_msgSender()] += amount;

        require(
            mintedPerAddress[_msgSender()] <= _publicMintConfig.maxPerWallet,
            "Too many tokens minted for this address"
        );

        uint256 cost = _publicMintConfig.ethPrice * amount;
        chargeEth(cost);

        mint(_msgSender(), amount);
    }

    function mintFromCoupon(
        MintCoupon calldata _coupon,
        uint256 amount
    ) public payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        checkSupplyAvailable(amount);
        validateCouponSignature(_coupon);
        validateCouponData(_coupon);

        mintedPerCoupon[_coupon.id] += amount;
        require(
            mintedPerCoupon[_coupon.id] <= _coupon.maxAmount,
            "Too many tokens minted for this coupon"
        );
        chargeEth(_coupon.ethPrice * amount);
        
        mint(_msgSender(), amount);
    }

    // OVERRIDING STUFF

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
