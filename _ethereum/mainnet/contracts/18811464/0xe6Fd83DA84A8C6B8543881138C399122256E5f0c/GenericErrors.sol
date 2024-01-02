// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


error CannotAuthoriseSelf();
error ContractCallNotAllowed();
error CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
error InformationMismatch();
error InsufficientBalance(uint256 required, uint256 balance);
error InvalidAmount();
error InvalidContract();
error InvalidIndex();
error IncorrectFeePercent();
error FeeMoreThanFee(uint256 amount, uint256 fee);
error EmptySwapPath();
error IncorrectMsgValue();
error IncorrectWETH();
error InvalidReceiver();
error NotAllowedTo(address account, bytes4 selector);
error NativeAssetTransferFailed();
error NoSwapFromZeroBalance();
error NoTransferToNullAddress();
error NullAddrIsNotAnERC20Token();
error NullAddrIsNotAValidSpender();
error OnlyContractOwner();
error ReentrancyError();
error TokenNotSupported();
error UnsupportedChainId(uint256 chainId);

// error RecoveryAddressCannotBeZero();
// error NotAContract();
// error NotInitialized();

// error UnAuthorized();
// error WithdrawFailed();
// error ZeroAmount();
// error AlreadyInitialized();
// error CannotBridgeToSameNetwork();
// error ExternalCallFailed();
// error InvalidCallData();
// error InvalidConfig();
// error InvalidDestinationChain();
// error InvalidFallbackAddress();
// error InvalidReceivedAmount(uint256 expected, uint256 received);
// error InvalidSendingToken();
// error NativeAssetNotSupported();
// error NoSwapDataProvided();