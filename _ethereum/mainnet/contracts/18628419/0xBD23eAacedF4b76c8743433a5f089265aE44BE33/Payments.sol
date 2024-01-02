// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract Payments is ReentrancyGuard {
    using SafeERC20 for IERC20;
    struct Payment {
      address to;
      uint256 amount;
    }

    // Event to log batch payments
    event BatchPaymentSent(
      string transactionId,
      address indexed sender
    ); 

    receive() external virtual payable {
      revert("Contract does not accept Ether");
    }

    function sendBatchPayments(
      string calldata _transactionId,
      IERC20 _token,
      Payment[] calldata _payments
    ) external nonReentrant {
      require(_payments.length > 0, "No recipients");
      require(_token != IERC20(address(0)), "Token cannot be zero address");

      uint256 totalAmount = 0;
      for (uint256 i = 0; i < _payments.length; i++) {
        totalAmount += _payments[i].amount;
      }

      uint256 senderBalance = _token.balanceOf(msg.sender);
      require(senderBalance >= totalAmount, "Sender does not have enough balance");

      // Transfer tokens from sender to contract
      uint256 allowance = _token.allowance(msg.sender, address(this));
      require(allowance >= totalAmount, "Allowance not set or insufficient");
      SafeERC20.safeTransferFrom(_token, msg.sender, address(this), totalAmount);

      // Transfer tokens from contract to receivers
      for (uint256 i = 0; i < _payments.length; i++) {
        require(_payments[i].to != address(0), "Receiver cannot be zero address");
        SafeERC20.safeTransfer(_token, _payments[i].to, _payments[i].amount);
      }

      emit BatchPaymentSent(_transactionId, msg.sender);
    }
}
