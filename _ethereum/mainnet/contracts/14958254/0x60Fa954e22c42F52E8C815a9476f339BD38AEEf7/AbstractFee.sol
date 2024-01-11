// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ACLAuth.sol";
import "./Math.sol";

abstract contract AbstractFee is ACLAuth {
  using SafeERC20 for IERC20;

  struct Fee {
    uint256 accumulated;
    uint256 bps;
    address recipient;
    IERC20 token;
  }
  mapping(bytes32 => Fee) public fees;
  bytes32[] public feeTypes;

  event FeeUpdated(bytes32 feeType, uint256 newRedemptionFee, address newFeeRecipient, address toke);
  event FeesClaimed(bytes32 feeType, address recipient, uint256 amount, address token);

  function _takeFee(
    bytes32 feeType,
    uint256 fee,
    uint256 balance,
    IERC20 token
  ) internal returns (uint256) {
    Fee memory currFee = fees[feeType];

    require(token == currFee.token, "fee token mismatch");

    fee = Math.min((balance * currFee.bps) / 10_000, fee); // the client can tell us the fee they want to take, but it's higher than the threshold defined, we'll set a ceiling

    fees[feeType].accumulated += fee;

    return balance - fee;
  }

  /**
   * @notice Changes the redemption fee rate and the fee recipient
   * @param feeType A short string signaling if its a "mint"/"redeem" or any other type of fee
   * @param bps Redemption fee rate in basis points
   * @param recipient The recipient which receives these fees (Should be DAO treasury)
   * @param token the token which the fee is taken in
   * @dev Per default both of these values are not set. Therefore a fee has to be explicitly be set with this function
   * @dev Adds the feeType to the list of feeTypes if it is not already there
   */
  function setFee(
    bytes32 feeType,
    uint256 bps,
    address recipient,
    IERC20 token
  ) external onlyRole(DAO_ROLE) {
    _setFee(feeType, bps, recipient, token);

    emit FeeUpdated(feeType, bps, recipient, address(token));
  }

  function _setFee(
    bytes32 feeType,
    uint256 bps,
    address recipient,
    IERC20 token
  ) internal {
    require(bps <= 100, "dont be greedy");

    if (address(fees[feeType].token) == address(0)) {
      feeTypes.push(feeType);
    }

    fees[feeType].bps = bps;
    fees[feeType].recipient = recipient;
    fees[feeType].token = token;
  }

  /**
   * @notice Claims all accumulated redemption fees in DAI
   * @param feeType A short string signaling if its a "mint"/"redeem" or any other type of fee
   */
  function claimRedemptionFee(bytes32 feeType) external {
    Fee memory currFee = fees[feeType];

    currFee.token.safeTransfer(currFee.recipient, currFee.accumulated);

    fees[feeType].accumulated = 0;

    emit FeesClaimed(feeType, currFee.recipient, currFee.accumulated, address(currFee.token));
  }
}
