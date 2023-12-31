// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "./IFlashLoanSimpleReceiver.sol";

interface ILeverager is IFlashLoanSimpleReceiver {
  /**
   * @dev Emitted when the sender swap tokens.
   * @param account Address who create operation.
   * @param toToken The address of the token to buy.
   * @param fromToken The address of the token to sell.
   * @param amount The amount of the token to sell.
   * @param buyAmount The amount of tokens received.
   */
  event Exchange(
    address indexed account,
    address toToken,
    address fromToken,
    uint256 amount,
    uint256 buyAmount
  );

  /**
   * @dev Emitted when a user opens a new position.
   * @param account Address of the user who opened the position.
   * @param supplyAmount The amount of the asset supplied to the protocol.
   * @param collateralAmount The amount of collateral provided.
   * @param debtAmount The amount of debt taken on by the user.
   * @param flashLoanFee The fee associated with using the flash loan.
   * @param protocolFee The fee taken by the protocol for the operation.
   */
  event OpenPosition(
    address indexed account,
    uint256 supplyAmount,
    uint256 collateralAmount,
    uint256 debtAmount,
    uint256 flashLoanFee,
    uint256 protocolFee
  );

  /**
   * @dev Emitted when a user closes an existing position.
   * @param account Address of the user who closed the position.
   * @param withdrawnAmount The amount withdrawn from the position.
   * @param repaidAmount The amount repaid to cover the debt.
   * @param flashLoanFee The fee associated with using the flash loan for closing.
   * @param protocolFee The fee taken by the protocol for the operation.
   */
  event ClosePosition(
    address indexed account,
    uint256 withdrawnAmount,
    uint256 repaidAmount,
    uint256 flashLoanFee,
    uint256 protocolFee
  );

  /**
   * @dev Initiates a flashloan leveraging mechanism.
   * @notice Users must approve this contract for COLLATERAL_ASSET and DEBT_ASSET prior to call.
   *         Users must approveDelegation to this contract prior to call.
   *         Users must use reserve as collateral.
   * @param amount Amount to be used as basis for the flashloan.
   * @param multiplier Multiplier for flashloan amount. Determines how much will be borrowed in relation to the user's input.
   * @param data Data from router(1Inch or Uniswap) API.
   */
  function openPosition(uint256 amount, uint256 multiplier, bytes calldata data) external;

  /**
   * @dev Initiates a flashloan leveraging mechanism to close a position.
   * @notice Users must approve this contract for asDAI prior to call.
   *         User inputs the amount of the debt asset to be repaid
   * -> send api call to 1inch or uniswap to get the amount of DAI to be flashloaned - debt asset -> DAI
   * -> pass the DAI amount to this amount parameter
   * -> send api call again to 1inch or uniswap to get the calldata for the swap - DAI -> debt asset
   * @param amount Amount to be used as basis for the flashloan.
   * @param data Data from router(1Inch or Uniswap) API.
   */
  function closePosition(uint256 amount, bytes calldata data) external;

  /**
   * @dev Approves the DAI to 1Inch or Uniswap router.
   * @param router Address of the router.
   */
  function approveRouter(address router) external;

  /**
   * @dev Calculates the amount to be borrowed from Aave v3.
   * @param asset The asset to be borrowed.
   * @param amount The origin amount of DAI supplied by the user.
   * @param multiplier Multiplier for flashloan amount. Determines how much will be borrowed in relation to the user's input.
   */
  function getBorrowAmount(
    address asset,
    uint256 amount,
    uint256 multiplier
  ) external view returns (uint256);

  /**
   * @dev Fetches the debt asset's address.
   * @return Address of the debt asset.
   */
  function DEBT_ASSET() external view returns (address);

  /**
   * @dev Fetches the current protocol fee.
   * @return Current protocol fee.
   */
  function PROTOCOL_FEE() external view returns (uint256);

  /**
   * @dev Fetches the DEX router's address.
   * @return Address of the DEX router.
   */
  function ROUTER() external view returns (address);

  /**
   * @dev Fetches the treasury's address.
   * @return Address of the treasury.
   */
  function TREASURY_ADDRESS() external view returns (address);

  /**
   * @dev Fetches the withdrawal ratio.
   * @return withdrawal ratio.
   */
  function WITHDRAWAL_RATIO() external view returns (uint256);

  /**
   * @dev Allows owner to update address of the debt asset.
   * @param debtAsset Address of the new debt asset.
   */
  function setDebtAsset(address debtAsset) external;

  /**
   * @dev Allows owner to set a new protocol fee.
   * @param protocolFee New fee for the protocol.
   */
  function setProtocolFee(uint256 protocolFee) external;

  /**
   * @dev Allows owner to set a new DEX router address.
   * @param router Address of the new DEX router.
   */
  function setRouter(address router) external;

  /**
   * @dev Allows owner to set a new treasury address.
   * @param treasuryAddress Address of the new treasury.
   */
  function setTreasuryAddress(address treasuryAddress) external;

  /**
   * @dev Allows owner to set a new withdrawal ratio.
   * @param withdrawalRatio New ratio for withdrawal.
   */
  function setWithdrawalRatio(uint256 withdrawalRatio) external;
}
