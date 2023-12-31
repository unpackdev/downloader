// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.20;

import "./Clones.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable2Step.sol";
import "./SafeERC20.sol";

error ForbiddenValue();

contract OrderFactory is Ownable2Step {
  using SafeERC20 for IERC20;

  uint16 private constant HUNDRED_PERCENT = 10000;
  uint16 public protocolFee = 25; // default 0.25% (range: 0-500 / 0-5%)

  event OrderCreated(address indexed order);

  /// @dev Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
  /// @param _singleton Address of singleton contract. Must be deployed at the time of execution.
  /// @param _initializer Payload for a message call to be sent to a new proxy contract.
  /// @param _saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
  function createProxy(address _singleton, bytes memory _initializer, uint256 _saltNonce)
    internal
    returns (address order)
  {
    // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
    bytes32 salt = keccak256(abi.encodePacked(keccak256(_initializer), _saltNonce));
    order = Clones.cloneDeterministic(_singleton, salt);

    if (_initializer.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        if eq(call(gas(), order, 0, add(_initializer, 0x20), mload(_initializer), 0, 0), 0) { revert(0, 0) }
      }
    }
  }

  /// @dev Allows to create a new order contract and execute a message call to the new order within one transaction.
  /// @param _singleton Address of singleton contract. Must be deployed at the time of execution.
  /// @param _owner The owner of the order.
  /// @param _receiver The receiver of the buyToken orders.
  /// @param _sellToken The token that is being traded in the order.
  /// @param _amount The amount of the DCA order.
  /// @param _buyToken The token that is DCA'd in the order.
  /// @param _startTime The start time of the DCA order.
  /// @param _endTime The end time of the DCA order.
  /// @param _interval The frequency interval of the DCA order in hours.
  /// @param _settlementContract The settlement contract address.
  /// @param _saltNonce Nonce that will be used to generate the salt to calculate the address of the new order contract.
  function createOrderWithNonce(
    address _singleton,
    address _owner,
    address _receiver,
    address _sellToken,
    address _buyToken,
    uint256 _amount,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _interval,
    address _settlementContract,
    uint256 _saltNonce
  ) public returns (address order) {
    uint256 feeAmount = (_amount * protocolFee) / HUNDRED_PERCENT;
    uint256 amountWithoutFees = _amount - feeAmount;

    bytes memory initializer = abi.encodeWithSignature(
      "initialize(address,address,address,address,uint256,uint256,uint256,uint256,address)",
      _owner,
      _receiver,
      _sellToken,
      _buyToken,
      amountWithoutFees,
      _startTime,
      _endTime,
      _interval,
      _settlementContract
    );

    // Deploy a new order
    order = createProxy(_singleton, initializer, _saltNonce);

    emit OrderCreated(order);

    // Transfer the amount to the order
    IERC20(_sellToken).safeTransferFrom(msg.sender, order, amountWithoutFees);

    // Transfer the fee to the factory
    IERC20(_sellToken).safeTransferFrom(msg.sender, address(this), feeAmount);
  }

  /// @dev Set the protocol fee percent
  /// @param _fee The new protocol fee percent 0-5% (range: 0-500)
  function setProtocolFee(uint16 _fee) external onlyOwner {
    if (_fee > 500) revert ForbiddenValue();
    protocolFee = _fee;
  }

  /// @dev Withdraw protocol fee share
  /// @param tokens Tokens' addresses transferred to the owner as protocol fee
  function withdrawTokens(address[] calldata tokens) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).safeTransfer(owner(), IERC20(tokens[i]).balanceOf(address(this)));
    }
  }
}
