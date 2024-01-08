// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IMillionPieces.sol";
import "./IAuction.sol";
import "./IPiece.sol";
import "./ProxyRegistry.sol";


/**
 * @title Auction
 */
contract Auction is IAuction, Ownable {
  using SafeMath for uint256;

  uint256 public constant BATCH_PURCHASE_LIMIT = 25;
  uint256 public constant PRICE_FOR_SEGMENT = 0.03 ether;
  uint256 public constant CLAIMABLE_PIECE = 30 ether;

  IPiece public piece;
  address payable public fund;
  address public immutable proxyRegistryAddress;
  IMillionPieces public immutable millionPieces;

  event NewPurchase(address purchaser, address receiver, uint256 tokenId, uint256 weiAmount);

  constructor(
    address _pieceToken,
    address _millionPieces,
    address payable _fund,
    address _proxyRegistryAddress
  ) public {
    piece = IPiece(_pieceToken);
    fund = _fund;
    proxyRegistryAddress = _proxyRegistryAddress;
    millionPieces = IMillionPieces(_millionPieces);
  }

  fallback () external payable { revert(); }
  receive () external payable { revert(); }

  //  --------------------
  //  PUBLIC
  //  --------------------

  function buySingle(address receiver, uint256 tokenId) external payable override {
    require(msg.value >= PRICE_FOR_SEGMENT, "buySingle: Not enough ETH for purchase!");

    _buySingle(receiver, tokenId);
  }

  function buyMany(
    address[] calldata receivers,
    uint256[] calldata tokenIds
  ) external payable override {
    uint256 tokensCount = tokenIds.length;
    require(tokensCount > 0 && tokensCount <= BATCH_PURCHASE_LIMIT, "buyMany: Arrays should bigger 0 and less then max limit!");
    require(tokensCount == receivers.length, "buyMany: Arrays should be equal to each other!");
    require(msg.value >= tokensCount.mul(PRICE_FOR_SEGMENT), "buyMany: Not enough ETH for purchase!");

    _buyMany(receivers, tokenIds);
  }

  function mint(uint256 tokenId, address receiver) public {
    // Must be sent from the owner proxy or owner.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    require(address(proxyRegistry.proxies(owner())) == msg.sender || owner() == msg.sender, "mint: Not auth!");

    _buySingle(receiver, tokenId);
  }

  function changeFundAddress(address payable newFund) external onlyOwner {
    require(newFund != address(0), "changeFundAddress: Empty fund address!");
    fund = newFund;
  }

  //  --------------------
  //  INTERNAL
  //  -------------------

  function _buySingle(address receiver, uint256 tokenId) private {
    // Mint token to receiver
    _mintNft(receiver, tokenId);

    piece.mint(receiver, CLAIMABLE_PIECE);

    // Emit single segment purchase event
    emit NewPurchase(msg.sender, receiver, tokenId, msg.value);

    // Send ETH to fund address
    _transferEth(fund, msg.value);
  }

  function _buyMany(address[] memory receivers, uint256[] memory tokenIds) private {
    uint256 tokensCount = tokenIds.length;
    uint256 actualPurchasedSegments = 0;
    uint256 ethPerEachSegment = msg.value.div(tokensCount);

    for (uint256 i = 0; i < tokensCount; i++) {
      // Transfer if tokens not exist, else sent ETH back to purchaser
      if (_isPurchasable(tokenIds[i])) {
        // Mint token to receiver
        _mintNft(receivers[i], tokenIds[i]);

        // Mint piece to receiver
        piece.mint(receivers[i], CLAIMABLE_PIECE);
        actualPurchasedSegments++;

        emit NewPurchase(msg.sender, receivers[i], tokenIds[i], ethPerEachSegment);
      }
    }

    // Send ETH to fund address
    _transferEth(fund, actualPurchasedSegments.mul(ethPerEachSegment));

    // Send non-purchased funds to sender address back
    if (tokensCount != actualPurchasedSegments) {
      _transferEth(msg.sender, (tokensCount.sub(actualPurchasedSegments)).mul(ethPerEachSegment));
    }
  }

  /**
   * @notice Transfer amount of ETH to the fund address.
   */
  function _transferEth(address receiver, uint256 amount) private {
    (bool success, ) = receiver.call{value: amount}("");
    require(success, "_transferEth: Failed to transfer funds!");
  }

  /**
   * @notice Mint simple segment.
   */
  function _mintNft(address receiver, uint256 tokenId) private {
    millionPieces.mintTo(receiver, tokenId);
  }

  /**
   * @notice Is provided token exists or not.
   */
  function _isPurchasable(uint256 tokenId) private view returns (bool) {
    return !millionPieces.exists(tokenId);
  }
}