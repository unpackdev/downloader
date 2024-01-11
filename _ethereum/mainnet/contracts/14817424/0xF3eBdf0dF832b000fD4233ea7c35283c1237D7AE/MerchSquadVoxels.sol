// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProductToken.sol";

import "./SlicerPurchasable.sol";
import "./ERC1155Receiver.sol";
import "./Ownable.sol";

contract MerchSquadVoxels is SlicerPurchasable, ERC1155Receiver, Ownable {
    error Invalid();

    /// ============ Storage ============

    // Mapping from Product ID to erc1155 tokenId
    mapping(uint256 => ProductToken) private _productTokens;

    /// ========== Constructor ===========

    constructor(address productsModuleAddress_, uint256 slicerId_)
        SlicerPurchasable(productsModuleAddress_, slicerId_)
    {}

    /// ============ Functions ============

    // /**
    //  * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
    //  *
    //  * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
    //  * @dev Max quantity purchasable per address and total mint amount is handled on Slicer product logic
    //  */
    // function isPurchaseAllowed(
    //     uint256,
    //     uint256,
    //     address,
    //     uint256,
    //     bytes memory,
    //     bytes memory
    // ) public view override returns (bool isAllowed) {
    //     // Add all requirements related to product purchase here
    //     // Return true if account is allowed to buy product
    //     return true;
    // }

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory,
        bytes memory
    ) external payable override onlyOnPurchaseFrom(slicerId) {
        // Check whether the account is allowed to buy a product.
        // if (
        //     !isPurchaseAllowed(
        //         slicerId,
        //         productId,
        //         account,
        //         quantity,
        //         slicerCustomData,
        //         buyerCustomData
        //     )
        // ) revert NotAllowed();

        // Add product purchase logic here
        ProductToken memory p = _productTokens[productId];

        uint256[] memory amounts = new uint256[](p.tokenIds.length);

        for (uint256 i; i < p.tokenIds.length; ) {
            amounts[i] = quantity;
            unchecked {
                ++i;
            }
        }

        p.contractAddress.safeBatchTransferFrom(address(this), account, p.tokenIds, amounts, "");
    }

    /**
     * @notice Sets a `productId` to execute the transfer of a certain `tokenId`
     */
    function setTokenIdToProduct(
        uint256 productId,
        IERC1155 erc1155,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        _productTokens[productId] = ProductToken(erc1155, tokenIds);
    }

    /**
     * @notice Function called when ERC1155 tokens are received
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See `onERC1155Received`
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
