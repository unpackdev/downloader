// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC165.sol";
import "./JBDidRedeemData.sol";

interface IJBRedemptionDelegate is IERC165 {
  function didRedeem(JBDidRedeemData calldata _data) external;
}
