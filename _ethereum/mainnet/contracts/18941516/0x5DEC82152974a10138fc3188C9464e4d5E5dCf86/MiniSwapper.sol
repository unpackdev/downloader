// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Rescuable.sol";
import "./OwnableWithGuardian.sol";
import "./AaveV3Ethereum.sol";
import "./ComposableCoW.sol";
import "./ERC1271Forwarder.sol";
import "./IConditionalOrder.sol";

struct TWAPData {
  IERC20 sellToken;
  IERC20 buyToken;
  address receiver;
  uint256 partSellAmount; // amount of sellToken to sell in each part
  uint256 minPartLimit; // max price to pay for a unit of buyToken denominated in sellToken
  uint256 t0;
  uint256 n;
  uint256 t;
  uint256 span;
  bytes32 appData;
}

/// @title AaveSwapper
/// @author efecarranza.eth
/// @notice Helper contract to swap assets using milkman
contract MiniSwapper is OwnableWithGuardian, Rescuable, ERC1271Forwarder {
  using SafeERC20 for IERC20;

  event TWAPSwapCanceled(address indexed fromToken, address indexed toToken, uint256 amount);
  event TWAPSwapRequested(
    address handler,
    address indexed fromToken,
    address indexed toToken,
    address recipient,
    uint256 totalAmount
  );

  /// @notice Provided address is zero address
  error Invalid0xAddress();

  /// @notice Amount needs to be greater than zero
  error InvalidAmount();

  /// @notice Recipient cannot be the zero address
  error InvalidRecipient();

  constructor(address _composableCoW) ERC1271Forwarder(ComposableCoW(_composableCoW)) {}

  function twapSwap(
    address handler,
    address relayer,
    address fromToken,
    address toToken,
    address recipient,
    uint256 sellAmount,
    uint256 minPartLimit,
    uint256 startTime,
    uint256 numParts,
    uint256 partDuration,
    uint256 span
  ) external onlyOwner {
    if (fromToken == address(0) || toToken == address(0)) revert Invalid0xAddress();
    if (recipient == address(0)) revert InvalidRecipient();
    if (sellAmount == 0 || numParts == 0) revert InvalidAmount();

    TWAPData memory twapData = TWAPData(
      IERC20(fromToken),
      IERC20(toToken),
      recipient,
      sellAmount,
      minPartLimit,
      startTime,
      numParts,
      partDuration,
      span,
      bytes32(0)
    );
    IConditionalOrder.ConditionalOrderParams memory params = IConditionalOrder
      .ConditionalOrderParams(
        IConditionalOrder(handler),
        'AaveSwapper-TWAP-Swap',
        abi.encode(twapData)
      );
    composableCoW.create(params, true);

    IERC20(fromToken).forceApprove(relayer, sellAmount * numParts);
    emit TWAPSwapRequested(handler, fromToken, toToken, recipient, sellAmount * numParts);
  }

  function cancelTwapSwap(
    address handler,
    address fromToken,
    address toToken,
    address recipient,
    uint256 sellAmount,
    uint256 minPartLimit,
    uint256 startTime,
    uint256 numParts,
    uint256 partDuration,
    uint256 span
  ) external onlyOwnerOrGuardian {
    TWAPData memory twapData = TWAPData(
      IERC20(fromToken),
      IERC20(toToken),
      recipient,
      sellAmount,
      minPartLimit,
      startTime,
      numParts,
      partDuration,
      span,
      bytes32(0)
    );
    IConditionalOrder.ConditionalOrderParams memory params = IConditionalOrder
      .ConditionalOrderParams(
        IConditionalOrder(handler),
        'AaveSwapper-TWAP-Swap',
        abi.encode(twapData)
      );
    bytes32 hashedOrder = composableCoW.hash(params);
    composableCoW.remove(hashedOrder);
    emit TWAPSwapCanceled(fromToken, toToken, sellAmount * numParts);
  }

  /// @inheritdoc Rescuable
  function whoCanRescue() public view override returns (address) {
    return owner();
  }
}
