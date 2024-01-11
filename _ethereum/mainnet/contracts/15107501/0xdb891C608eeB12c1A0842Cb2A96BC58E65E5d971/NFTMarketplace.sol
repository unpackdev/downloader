// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./BaseMarketPlace.sol";
//import "./console.sol";

contract NFTMarketplace is BaseMarketPlace {
  using Address for address;
  using SafeMath for uint256;

  constructor(address marketAddress, address admin) BaseMarketPlace(marketAddress, admin) {}

  /**
   * @dev Batch Create a new order
   * @param nftAddress - Non fungible registry address
   * @param assetIds - ID of the published NFT
   * @param priceAsset - Price in Wei for the supported coin
   */
  function batchCreateOrder(
    address nftAddress,
    uint256[] memory assetIds,
    uint256 priceAsset,
    uint256 expireAt
  ) external {
    for (uint8 i = 0; i < assetIds.length; i++) {
      _createOrder(nftAddress, assetIds[i], priceAsset, expireAt);
    }
  }

  /**
   * @dev Creates a new order
   * @param nftAddress - Non fungible registry address
   * @param assetId - ID of the published NFT
   * @param priceAsset - Price in Wei for the supported coin
   */
  function createOrder(
    address nftAddress,
    uint256 assetId,
    uint256 priceAsset,
    uint256 expireAt
  ) external {
    _createOrder(nftAddress, assetId, priceAsset, expireAt);
  }

  /**
   * @dev Cancel an already published order
   *  can only be canceled by seller or the contract owner
   * @param nftAddress - Address of the NFT registry
   * @param assetId - ID of the published NFT
   */
  function cancelOrder(address nftAddress, uint256 assetId) external {
    _cancelOrder(nftAddress, assetId);
  }

  /**
   * @dev Executes the sale for a published NFT
   * @param nftAddress - Address of the NFT registry
   * @param assetId - ID of the published NFT
   */
  function executeOrder(
    address nftAddress,
    address assetOwner,
    uint256 assetId,
    uint256 price,
    bytes memory signature
  ) external payable {
    // Require signature
    bytes32 message = prefixed(
      keccak256(abi.encodePacked(nftAddress, assetOwner, assetId, price))
    );
    require(recoverSigner(message, signature) == _admin, 'wrong signature');

    _requireIERC721(nftAddress);

    // Require valid pay price
    require(price == msg.value, 'Invalid pay amount');

    address buyer = _msgSender();
    uint256 payAmount = msg.value;

    IERC721 nftRegistry = IERC721(nftAddress);

    // Verify required
    require(assetOwner != address(0), 'Invalid address');
    require(assetOwner != buyer, 'Owner cannot buy their own item');

    Order memory order = orderByAssetId[nftAddress][assetId][assetOwner];
    bytes32 orderId = order.id;

    require(orderId != 0, 'Asset order not created');
    require(
      assetOwner == nftRegistry.ownerOf(assetId),
      'The seller is no longer the owner'
    );

    // Set seller payable
    address payable seller = payable(address(order.seller));

    // Remove assetId from orderByAssetId
    delete orderByAssetId[nftAddress][assetId][seller];

    // Calculate
    uint256 fee = _marketFee(payAmount);
    uint256 paySeller = SafeMath.sub(payAmount, fee);

    // Transfer fee and transfer money to seller
    seller.transfer(paySeller);
    _marketAddress.transfer(fee);

    // Transfer asset owner
    nftRegistry.safeTransferFrom(seller, buyer, assetId);

    emit OrderSuccessful(
      orderId,
      assetId,
      seller,
      order.nftAddress,
      payAmount,
      buyer
    );
  }
}
