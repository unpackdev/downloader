// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC1271.sol";
import "./SafeERC20.sol";
import "./draft-EIP712.sol";

import "./IWETH.sol";
import "./IRFQ.sol";

import "./KSAdmin.sol";

/// Taken from 1inch Router at 0x1111111254fb6c44bac0bed2854e76f90643097d
/// with minor modifications
/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/
contract KyberSwapRFQ is IRFQ, EIP712('KyberSwap RFQ', '1'), KSAdmin {
  using SafeERC20 for IERC20;

  event OrderFilledRFQ(
    bytes32 orderHash,
    address indexed maker,
    address indexed taker,
    address makerAsset,
    address takerAsset,
    uint256 makingAmount,
    uint256 takingAmount
  );

  bytes32 public constant LIMIT_ORDER_RFQ_TYPEHASH =
    keccak256(
      // solhint-disable-next-line
      'OrderRFQ(uint256 info,address makerAsset,address takerAsset,address maker,address allowedSender,uint256 makingAmount,uint256 takingAmount)'
    );
  uint256 private constant _UNWRAPWETH_MASK = 1 << 255;
  IWETH private immutable WETH;
  mapping(address => mapping(uint256 => uint256)) private invalidator;

  constructor(IWETH _weth) {
    WETH = IWETH(_weth);
  }

  receive() external payable {
    // solhint-disable-next-line avoid-tx-origin
    // ETH should only come from WETH contract
    require(msg.sender == address(WETH), 'KS_RFQ: Not WETH contract');
  }

  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }

  function rescueFund(IERC20 token, uint256 amount) external isAdmin {
    if (address(token) == address(0)) {
      (bool success, ) = payable(msg.sender).call{value: amount}('');
      require(success, 'rescueFund: failed to collect native');
    } else {
      token.safeTransfer(msg.sender, amount);
    }
    emit RescueFund(address(token), amount);
  }

  /// @notice Returns bitmask for double-spend invalidators based on lowest byte of order.info and filled quotes
  /// @return Result Each bit represents whenever corresponding quote was filled
  function invalidatorForOrderRFQ(address maker, uint256 slot) external view returns (uint256) {
    return invalidator[maker][slot];
  }

  /// @notice Cancels order's quote
  function cancelOrderRFQ(uint256 orderInfo) external {
    _invalidateOrder(msg.sender, orderInfo);
  }

  /// @notice Fills an order's quote, either fully or partially
  /// @dev Funds will be sent to msg.sender
  /// @param order Order quote to fill
  /// @param signature Signature to confirm quote ownership
  /// @param makingAmount Maker amount
  /// @param takingAmount Taker amount
  function fillOrderRFQ(
    OrderRFQ memory order,
    bytes memory signature,
    uint256 makingAmount,
    uint256 takingAmount
  )
    external
    payable
    returns (
      uint256, /* actualmakingAmount */
      uint256 /* actualtakingAmount */
    )
  {
    return fillOrderRFQTo(order, signature, makingAmount, takingAmount, payable(msg.sender));
  }

  /// @notice Main function for fulfilling orders
  /// @param order Order quote to fill
  /// @param signature Signature to confirm quote ownership
  /// @param makingAmount Maker amount
  /// @param takingAmount Taker amount
  /// @param target Address that will receive swapped funds
  function fillOrderRFQTo(
    OrderRFQ memory order,
    bytes memory signature,
    uint256 makingAmount,
    uint256 takingAmount,
    address payable target
  )
    public
    payable
    returns (
      uint256, /* actualmakingAmount */
      uint256 /* actualtakingAmount */
    )
  {
    address maker = order.maker;
    bool unwrapWETH = (order.info & _UNWRAPWETH_MASK) > 0;
    {
      // Stack too deep
      uint256 info = order.info;
      // Check time expiration
      uint256 expiration = uint128(info) >> 64;
      require(expiration == 0 || block.timestamp <= expiration, 'KS_RFQ: order expired');
      _invalidateOrder(maker, info);
    }

    {
      // stack too deep
      uint256 orderMakingAmount = order.makingAmount;
      uint256 orderTakingAmount = order.takingAmount;
      // Compute partial fill if needed
      // Both zeros = fill whole order
      if (takingAmount == 0 && makingAmount == 0) {
        makingAmount = orderMakingAmount;
        takingAmount = orderTakingAmount;
      } else if (takingAmount == 0) {
        // makingAmount specified, calculate takingAmount
        require(makingAmount <= orderMakingAmount, 'KS_RFQ: maker amount exceeded');
        // expected amount = orderTakingAmount * makingAmount / orderMakingAmount
        // add taker fee: (orderMakingAmount - 1) / orderMakingAmount
        takingAmount = (orderTakingAmount * makingAmount + orderMakingAmount - 1) / orderMakingAmount;
      } else if (makingAmount == 0) {
        // takingAmount specified, calculate makingAmount
        require(takingAmount <= orderTakingAmount, 'KS_RFQ: taker amount exceeded');
        makingAmount = (orderMakingAmount * takingAmount) / orderTakingAmount;
      } else {
        revert('KS_RFQ: both amounts are non-zero');
      }
    }

    require(makingAmount > 0 && takingAmount > 0, "KS_RFQ: can't swap zero amount");

    // Validate order
    require(order.allowedSender == address(0) || order.allowedSender == msg.sender, 'KS_RFQ: private order');
    bytes32 orderHash = _hashTypedDataV4(keccak256(abi.encode(LIMIT_ORDER_RFQ_TYPEHASH, order)));
    _validate(maker, orderHash, signature);

    // Maker => Taker
    if (order.makerAsset == address(WETH) && unwrapWETH) {
      IERC20(order.makerAsset).safeTransferFrom(maker, address(this), makingAmount);
      WETH.withdraw(makingAmount);
      target.transfer(makingAmount);
    } else {
      IERC20(order.makerAsset).safeTransferFrom(maker, target, makingAmount);
    }

    // Taker => Maker
    if (address(order.takerAsset) == address(WETH) && msg.value > 0) {
      require(msg.value == takingAmount, 'KS_RFQ: wrong msg.value');
      WETH.deposit{value: takingAmount}();
      WETH.transfer(maker, takingAmount);
    } else {
      require(msg.value == 0, 'KS_RFQ: wrong msg.value');
      IERC20(order.takerAsset).safeTransferFrom(msg.sender, maker, takingAmount);
    }

    emit OrderFilledRFQ(orderHash, maker, target, order.makerAsset, order.takerAsset, makingAmount, takingAmount);
    return (makingAmount, takingAmount);
  }

  function _validate(
    address signer,
    bytes32 orderHash,
    bytes memory signature
  ) private view {
    (address recoveredSigner, ) = ECDSA.tryRecover(orderHash, signature);
    require(recoveredSigner != address(0), 'KS_RFQ: invalid signer');
    if (recoveredSigner != signer) {
      (bool success, bytes memory result) = signer.staticcall(
        abi.encodeWithSelector(IERC1271.isValidSignature.selector, orderHash, signature)
      );
      require(
        success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector,
        'KS_RFQ: bad signature'
      );
    }
  }

  function _invalidateOrder(address maker, uint256 orderInfo) private {
    uint256 invalidatorSlot = uint64(orderInfo) >> 8;
    uint256 invalidatorBit = 1 << uint8(orderInfo);
    mapping(uint256 => uint256) storage invalidatorStorage = invalidator[maker];
    uint256 invalidated = invalidatorStorage[invalidatorSlot];
    require(invalidated & invalidatorBit == 0, 'KS_RFQ: invalidated order');
    invalidatorStorage[invalidatorSlot] = invalidated | invalidatorBit;
  }
}
