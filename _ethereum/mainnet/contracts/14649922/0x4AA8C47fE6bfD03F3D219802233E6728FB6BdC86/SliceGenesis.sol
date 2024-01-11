// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlicerPurchasable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./IProductsModule.sol";
import "./ISliceCore.sol";

/**
 * @title SliceGenesis
 * @author jjranalli
 *
 * @notice ERC721 Implementation that uses SlicerPurchasable extension to handle NFT drop for Slice V1 launch.
 *
 * - Relies on allowlist mechanic for all products except product #4
 * - product #4 is based on quantity of SLX token owned
 *
 * Won't be possible to create new allowlists once contract ownership is renounced.
 */
contract SliceGenesis is ERC721, SlicerPurchasable, Ownable {
    /// ============ Errors ============

    // Thrown when an invalid query is made
    error Invalid();
    // Thrown when max supply set is reached
    error MaxSupply();

    /// ============ Libaries ============

    using Counters for Counters.Counter;
    using Strings for uint256;

    /// ============ Storage ============

    // Token ID counter
    Counters.Counter private _tokenIds;
    // Addresses for initial mint
    address[] private ADDRESSES_TO_MINT = [
        0xff0C998D921394D89c5649712422622E3172480C,
        0xc2cA7A683Db047D221F5F8cF2de34361a399a6d5,
        0xA6FB48C1ab0CB9Ef3015D920fBb15860427008c5,
        0x5d95baEBB8412AD827287240A5c281E3bB30d27E,
        0x5C8e99481e9D02F9efDF45FF73268D7123D2817D,
        0x26FDc242eCCc144971e558FF458a4ec21B75D4E8,
        0x26416423d530b1931A2a7a6b7D435Fac65eED27d,
        0xf0549d13B142B37F0663E6B52CE54BD312A2eDaa
    ];
    // Max token supply
    uint16 private constant MAX_SUPPLY = 4200;
    // Slicer address
    address private _slicerAddress;
    // SLX Address
    address private _slxAddress;
    // Temporary URI
    string private _tempURI;
    // Base URI
    string private _baseURI;
    // SLX
    IERC20 private immutable _slx;
    // Mapping from productIds to Merkle roots
    mapping(uint256 => bytes32) _merkleRoots;

    /// ============ Constructor ============

    constructor(
        string memory name_,
        string memory symbol_,
        address slxAddress_,
        address sliceCoreAddress_,
        address productsModuleAddress_,
        uint256 slicerId_
    ) ERC721(name_, symbol_) SlicerPurchasable(productsModuleAddress_, slicerId_) {
        _slx = IERC20(slxAddress_);
        _slicerAddress = ISliceCore(sliceCoreAddress_).slicers(slicerId_);

        // Mint NFTs to those that already claimed from previous contract
        _initMint(ADDRESSES_TO_MINT);
    }

    /// ============ Functions ============

    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
     * @dev Max quantity purchasable per address and total mint amount is handled on Slicer product logic
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory,
        bytes memory buyerCustomData
    ) public view override returns (bool isAllowed) {
        // Check max supply is not exceeded
        if (_tokenIds.current() + quantity > MAX_SUPPLY) revert MaxSupply();

        // For all products except product #4, use allowlists
        if (productId != 4) {
            if (_merkleRoots[productId] != bytes32(0)) {
                // Get Merkle proof from buyerCustomData
                bytes32[] memory proof = abi.decode(buyerCustomData, (bytes32[]));

                // Generate leaf from account address
                bytes32 leaf = keccak256(abi.encodePacked(account));

                // Check if Merkle proof is valid
                isAllowed = MerkleProof.verify(proof, _merkleRoots[productId], leaf);
            } else {
                isAllowed = true;
            }
        } else {
            // Get purchased units
            uint256 purchasedUnits = IProductsModule(_productsModuleAddress).validatePurchaseUnits(
                account,
                slicerId,
                uint32(productId)
            );

            // Calculate total quantity purchased
            /// @dev Quantity is included in purchased units during purchase
            uint256 totalQuantity = msg.sender == _productsModuleAddress
                ? purchasedUnits
                : quantity + purchasedUnits;

            // Check if accounts holds at least (25k * totalQuantity) SLX
            isAllowed = _slx.balanceOf(account) >= totalQuantity * 25 * 10**21;
        }
    }

    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external payable override onlyOnPurchaseFrom(slicerId) {
        // Check whether the account is allowed to buy a product.
        if (
            !isPurchaseAllowed(
                slicerId,
                productId,
                account,
                quantity,
                slicerCustomData,
                buyerCustomData
            )
        ) revert NotAllowed();

        // Mint number of NFTs equal to purchased quantity
        for (uint256 i = 0; i < quantity; ) {
            _mint(account);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Returns URI of tokenId
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId > _tokenIds.current()) revert Invalid();

        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId.toString()))
                : _tempURI;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (_slicerAddress, salePrice / 10);
    }

    /**
     * Sets _baseURI
     *
     * @dev Only accessible to contract owner
     */
    function _setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    /**
     * Sets _tempURI
     *
     * @dev Only accessible to contract owner
     */
    function _setTempURI(string memory tempURI_) external onlyOwner {
        _tempURI = tempURI_;
    }

    /**
     * Sets merkleRoot for productId
     *
     * @dev Only accessible to contract owner
     */
    function _setMerkleRoot(uint256 productId, bytes32 merkleRoot) external onlyOwner {
        _merkleRoots[productId] = merkleRoot;
    }

    /**
     * Mints 1 NFT and increases tokenId
     */
    function _mint(address to) private {
        _tokenIds.increment();
        _safeMint(to, _tokenIds.current());
    }

    /**
     * Mints nfts to those who already claimed the previous collection from the allowlist
     *
     * @dev Only called during constructor
     */
    function _initMint(address[] memory addresses) private {
        for (uint256 i = 0; i < addresses.length; ) {
            _mint(addresses[i]);

            unchecked {
                ++i;
            }
        }
    }
}
