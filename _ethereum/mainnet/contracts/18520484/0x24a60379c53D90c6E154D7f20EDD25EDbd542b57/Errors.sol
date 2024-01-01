// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

error InputAmountTooSmall(uint256 amount);
error InputAmountTooLarge(uint256 amount);
error ParameterZeroNotAllowed();
error PriceOutOfLimit(uint256 price, uint256[2] priceLimit);
error ReserveOutOfLimit(uint256 reserve, uint256[2] reserveLimit);
error UtilizationInvalid(uint256 parameterUtilization);
error InsufficientBalance();
error EmptyAddress();
error FeePercentOutOfRange();
error FailToSend(address recipient);
error FailToExecute(address pool, bytes data);
error InvalidInput();
error Unauthorized();
error InvariantChanged(uint256 invariant, uint256 newInvariant);
error UtilizationChanged(uint256 newUtilization);
error LpAlreadyExist();
error LpNotExist();
error PoolAlreadyExist();
error CommandUnsupport();
error EtherNotAccept();
error DepositNotAllowed();
error InputBalanceNotMatch();
