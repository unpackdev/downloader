// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

// Imports
import "./IERC20.sol";
import "./TransferHelper.sol";

/**
 * This is an abstract contract implementing withdraw functions allowing
 * to take tokens or ethers out of the contract.
 */
abstract contract Withdrawable {
  /**
   * An event emitted on a successful withdrawal.
   *
   * @param to withdrawal destination address
   * @param token contract address of the token being withdrawn (address(0) for Ether)
   * @param amount withdrawal amount
   * @param fee withdrawal fee paid to SlickSwap
   */
  event Withdraw(address indexed to, address token, uint256 amount, uint256 fee);

  /**
   * An event emitted on a failed withdrawal.
   *
   * @param to withdrawal destination address
   * @param token contract address of the token being withdrawn (zero for Ether)
   * @param amount withdrawal amount
   * @param fee withdrawal fee paid to SlickSwap
   */
  event WithdrawFailed(address indexed to, address token, uint256 amount, uint256 fee);

  /**
   * Attempts to withdraw tokens (or Ether if token is address(0)) in the given amount, transferring
   * the fee out to the fee recipient.
   *
   * @param to withdrawal destination address
   * @param token contract address of the token being withdrawn (address(0) for Ether)
   * @param amount withdrawal amount
   * @param fee withdrawal fee paid to SlickSwap
   * @param feeRecipient address to send the fee to
   *
   * @return a flag that is true on a successful withdrawal
   */
  function _withdraw(address to, address token, uint256 amount, uint256 fee, address feeRecipient) internal returns (bool) {
    if (token == address(0)) {
      return _withdrawEther(to, amount, fee, feeRecipient);
    } else {
      return _withdrawToken(to, token, amount, fee, feeRecipient);
    }
  }

  /**
   * Attempts to withdraw tokens (and fee, if nonzero) to the address provided
   * using IERC-20 transfer() function.
   *
   * @param to withdrawal destination address
   * @param token contract address of the token being withdrawn (address(0) for Ether)
   * @param amount withdrawal amount
   * @param fee withdrawal fee paid to SlickSwap
   * @param feeRecipient address to send the fee to
   *
   * @return a flag that is true on a successful withdrawal
   */
  function _withdrawToken(address to, address token, uint256 amount, uint256 fee, address feeRecipient) internal returns (bool) {
    // invoke the transfer() function on the IERC-20 contract
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));

    // Special handling around noncompliant tokens (namely Tether)
    if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
      // log the event about failed withdrawal – maybe the user hasn't got enough tokens?
      emit WithdrawFailed(to, token, amount, fee);
      return false;
    }

    // Take a fee if it is specified
    if (fee > 0) {
      TransferHelper.safeTransfer(token, feeRecipient, fee);
    }

    // Emit successful withdrawal event
    emit Withdraw(to, token, amount, fee);

    return true;
  }

  /**
   * Attempts to withdraw ethers (and fee, if nonzero) to the address provided.
   *
   * @param to withdrawal destination address
   * @param amount withdrawal amount
   * @param fee withdrawal fee paid to SlickSwap
   * @param feeRecipient address to send the fee to
   *
   * @return a flag that is true on a successful withdrawal
   */
  function _withdrawEther(address to, uint256 amount, uint256 fee, address feeRecipient) internal returns (bool) {
    // send Ethers to the address
    (bool success,) = to.call{ value: amount }("");

    if (!success) {
      // log the event about failed withdrawal – maybe the user hasn't got enough Ether?
      emit WithdrawFailed(to, address(0), amount, fee);
      return false;
    }

    // Take a fee if it is specified
    if (fee > 0) {
      (success,) = feeRecipient.call{ value: fee }("");
      require(success, "Unable to capture withdrawal fee");
    }

    // Emit successful withdrawal event
    emit Withdraw(to, address(0), amount, fee);

    return true;
  }
}
