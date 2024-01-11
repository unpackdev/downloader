// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlicerPurchasable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract SharkStreet is ERC721, SlicerPurchasable, Ownable {
    /// ============ Errors ============

    // Thrown when max supply set is reached
    error MaxSupply();

    /// ============ Constructor ============

    constructor(
        address productsModuleAddress_,
        uint256 slicerId_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) SlicerPurchasable(productsModuleAddress_, slicerId_) {
        _mint(0x728A4DDe804aeDaF93AC839C9B0Fce031e0361af); // Marxist
        _mint(0x728A4DDe804aeDaF93AC839C9B0Fce031e0361af); // Marxist
        _mint(0xDEAD753f9B1eb8F2f7372E8587e7C6e342daac89); // Maty
        _mint(0x643e9a6158feaAdbe46c96a5a990DAFc4E746EB2); // Cryptasha
        _mint(0xE3f27DEFf96fe178e87559F36Cbf868B9E75967D); // Sasquatch
    }

    /// ============ Storage ============

    IERC20 private constant SHARK = IERC20(0x232AFcE9f1b3AAE7cb408e482E847250843DB931);
    IERC721 private constant GNARS = IERC721(0x494715B2a3C75DaDd24929835B658a1c19bd4552);
    IERC721 private constant BONEY_BATZ = IERC721(0x4d2bb7D45bBe10E43Ad1Ba569Ce85F19e85812A3);
    IERC721 private constant BULLFRUG_MUTANT_CLUB =
        IERC721(0x327d2E8bb8ac6F4b3E79f8c12609Cf9bcf9ac3F0);
    address private constant TREASURY_ADDRESS = 0xAe7f458667f1B30746354aBC3157907d9F6FD15E;
    uint8 private constant MAX_SUPPLY = 100;

    string private _tokenURI;
    uint256 private tokenId;

    /// ============ Functions ============

    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
     * @dev Max quantity purchasable per address and total mint amount is handled on Slicer product logic
     */
    function isPurchaseAllowed(
        uint256,
        uint256,
        address buyer,
        uint256,
        bytes memory,
        bytes memory
    ) public view override returns (bool isAllowed) {
        // Add all requirements related to product purchase here
        // Return true if account is allowed to buy product
        if (tokenId == MAX_SUPPLY) revert MaxSupply();
        isAllowed =
            SHARK.balanceOf(buyer) >= 10**22 ||
            GNARS.balanceOf(buyer) != 0 ||
            BONEY_BATZ.balanceOf(buyer) != 0 ||
            BULLFRUG_MUTANT_CLUB.balanceOf(buyer) != 0;
    }

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
     */
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

        // Mint 1 NFT
        _mint(account);
    }

    /**
     * @notice Returns URI of tokenId
     */
    function tokenURI(uint256) public view override returns (string memory) {
        return _tokenURI;
    }

    /**
     * @notice Returns totalSupply
     */
    function totalSupply() external view returns (uint256) {
        return tokenId;
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (TREASURY_ADDRESS, salePrice / 10);
    }

    /**
     * Mint 1 token to `account` and increases tokenId
     */
    function _mint(address account) private {
        tokenId++;
        _safeMint(account, tokenId);
    }

    /**
     * Set tokenURI
     *
     * @dev Only accessible to contract owner
     */
    function _setTokenURI(string memory tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }
}
