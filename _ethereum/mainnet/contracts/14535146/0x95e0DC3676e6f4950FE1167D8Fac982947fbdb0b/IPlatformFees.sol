// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPlatformFees {

  function setStakeFeeNumerator(uint256 numerator_) external;

  function setStakeFeeDenominator(uint256 denominator_) external;

  function setUnstakeFeeNumerator(uint256 numerator_) external;

  function setUnstakeFeeDenominator(uint256 denominator_) external;

  function setMinStakeAmount(uint256 _amount) external;

  function setStakeTxLimit(uint256 limit_) external;

  function setFeeWallet(address payable feeWallet_) external;

}
