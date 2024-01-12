//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./console.sol";

error MintIsPaused();
error MintIsPrivateOnly();
error MintIsPublicOnly();
error MintMoreThanMaxSupply();
error MintMoreThanTxnLimit();
error MintEthValueNotEnough();
error MintMoreThanWalletLimit();
error MintMoreThanAllocationLimit();
error MintCouponInvalid();
error MaxSupplyMoreThanMaxSupplyLimit();
error MaxSupplyLessThanTotalSupply();
error WithdrawFailed();

struct MintTally {
    uint128 privateSale;
    uint128 publicSale;
}

struct MintStatus {
    // contract wide info
    uint256 maxSupply;
    uint256 totalSupply;
    bool paused;
    bool publicSale;
    uint256 publicSaleMaxMintAmountPerTx;
    uint256 publicSaleMaxMintAmountPerWallet;
    uint256 publicMintPrice;
    // calling added based into
    uint256 publicBalance;
    uint256 privateBalance;
}

contract FreakyFools is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY_LIMIT = 2222;
    uint256 public constant MINT_COST = 0.00 ether;
    uint256 public constant MAX_MINT_AMOUNT_PER_TX = 3;
    uint256 public constant MAX_MINT_AMOUNT_PER_WALLET = 3;
    
    bool public paused = true;
    bool public revealed = false;
    bool public publicSale = false;
    uint256 public maxSupply = MAX_SUPPLY_LIMIT;

    // must be a form <protocol>://<path>/, i.e. it needs the trailing slash 
    string private _hiddenMetadataURI;
    string private _revealedMetadataBaseURI;
    address private _couponSigner;

    mapping(address=>MintTally) private _mintsByAddress;
    
    constructor(string memory hiddenMetadataURI, address couponSigner) ERC721A("FreakyFools", "FREAKS") {
        _hiddenMetadataURI = hiddenMetadataURI;
        _couponSigner = couponSigner;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mintStatus(address addr) external view returns (MintStatus memory) {
        return MintStatus(maxSupply, totalSupply(), paused, 
            publicSale, MAX_MINT_AMOUNT_PER_TX, MAX_MINT_AMOUNT_PER_WALLET, MINT_COST,
            _mintsByAddress[addr].publicSale, _mintsByAddress[addr].privateSale);
    }

    function publicMint(uint256 quantity) external payable {
        if (paused) revert MintIsPaused();
        if (!publicSale) revert MintIsPrivateOnly();
        if (quantity <= 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_AMOUNT_PER_TX) revert MintMoreThanTxnLimit();
        if (_currentIndex + quantity - _startTokenId() > maxSupply) revert MintMoreThanMaxSupply();
        if (_mintsByAddress[msg.sender].publicSale + quantity > MAX_MINT_AMOUNT_PER_WALLET) revert MintMoreThanWalletLimit();

        _mintsByAddress[msg.sender].publicSale += uint128(quantity);

        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, quantity);
    }

    function privateMint(uint256 quantity, uint256 allocation, bytes calldata coupon) external payable {
        if (paused) revert MintIsPaused();
        if (publicSale) revert MintIsPublicOnly();
        if (quantity <= 0) revert MintZeroQuantity();
        if (_currentIndex + quantity - _startTokenId() > maxSupply) revert MintMoreThanMaxSupply();
        if (_mintsByAddress[msg.sender].privateSale + quantity > allocation) revert MintMoreThanAllocationLimit();

        // some of the above checks are purely based on call args and they can't be trusted but they are done first
        // to have the most gas efficient failures first.  The verification of the coupon will check that the
        // call args are valid and if they are not then it will revert

        if (!_isValidCoupon(allocation, coupon)) revert MintCouponInvalid();

        _mintsByAddress[msg.sender].privateSale += uint128(quantity);

        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, quantity);
    }

    function reservedMint(uint256 quantity) external payable onlyOwner {
        if (quantity <= 0) revert MintZeroQuantity();
        if (_currentIndex + quantity - _startTokenId() > maxSupply) revert MintMoreThanMaxSupply();

        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return (revealed) ? super.tokenURI(tokenId) : _hiddenMetadataURI;
    }

    function _isValidCoupon(uint256 allocation, bytes memory coupon) internal view returns (bool) {
        
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, allocation));
        address signerAddress = msgHash.toEthSignedMessageHash().recover(coupon);

        return (signerAddress == _couponSigner);    
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return _revealedMetadataBaseURI;
    }

    function setRevealedMetadataBaseURI(string memory revealedMetadataBaseURI) external onlyOwner {
        _revealedMetadataBaseURI = revealedMetadataBaseURI;
    }

    function setHiddenMetadataURI(string memory hiddenMetadataURI) external onlyOwner {
        _hiddenMetadataURI = hiddenMetadataURI;
    }

    function setCouponSigner(address couponSigner) external onlyOwner {
        _couponSigner = couponSigner;
    }

    function setRevealed(bool revealed_) external onlyOwner {
        revealed = revealed_;
    }

    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
    }

    function setPublicSale(bool publicSale_) external onlyOwner {
        publicSale = publicSale_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        if (maxSupply_ > MAX_SUPPLY_LIMIT) revert MaxSupplyMoreThanMaxSupplyLimit();
        if (maxSupply_ < totalSupply()) revert MaxSupplyLessThanTotalSupply();

        maxSupply = maxSupply_;
    }

    function withdraw() external onlyOwner {
        // transfer the full value of the contract to the vault
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");

        if (!success) revert WithdrawFailed();
    }
}
