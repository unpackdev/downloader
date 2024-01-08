// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

/** @title Interface for interacting with the SelfMintingController
 */
interface ISelfMintingController {
  //Describe fee structure
  struct DaoFee {
    uint256 feePercentage;
    address feeRecipient;
  }

  /**
   * @notice Allow to set capMintAmount on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capMintAmounts Mint cap amounts for self-minting derivatives
   */
  function setCapMintAmount(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capMintAmounts
  ) external;

  /**
   * @notice Allow to set capDepositRatio on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capDepositRatios Deposit caps ratios for self-minting derivatives
   */
  function setCapDepositRatio(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capDepositRatios
  ) external;

  /**
   * @notice Allow to set Dao fees on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFees Dao fees for self-minting derivatives
   */
  function setDaoFee(
    address[] calldata selfMintingDerivatives,
    DaoFee[] calldata daoFees
  ) external;

  /**
   * @notice Allow to set Dao fee percentages on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFeePercentages Dao fee percentages for self-minting derivatives
   */
  function setDaoFeePercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata daoFeePercentages
  ) external;

  /**
   * @notice Allow to set Dao fee recipients on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFeeRecipients Dao fee recipients for self-minting derivatives
   */
  function setDaoFeeRecipient(
    address[] calldata selfMintingDerivatives,
    address[] calldata daoFeeRecipients
  ) external;

  /**
   * @notice Gets the set CapMintAmount of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return capMintAmount Limit amount for minting
   */
  function getCapMintAmount(address selfMintingDerivative)
    external
    view
    returns (uint256 capMintAmount);

  /**
   * @notice Gets the set CapDepositRatio of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return capDepositRatio Limit ratio for a user deposit
   */
  function getCapDepositRatio(address selfMintingDerivative)
    external
    view
    returns (uint256 capDepositRatio);

  /**
   * @notice Gets the set DAO fee of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return daoFee Dao fee info (percent + recipient)
   */
  function getDaoFee(address selfMintingDerivative)
    external
    view
    returns (DaoFee memory daoFee);

  /**
   * @notice Gets the set DAO fee percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return daoFeePercentage Dao fee percent
   */
  function getDaoFeePercentage(address selfMintingDerivative)
    external
    view
    returns (uint256 daoFeePercentage);

  /**
   * @notice Gets the set DAO fee recipient of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return recipient Dao fee recipient
   */
  function getDaoFeeRecipient(address selfMintingDerivative)
    external
    view
    returns (address recipient);
}
