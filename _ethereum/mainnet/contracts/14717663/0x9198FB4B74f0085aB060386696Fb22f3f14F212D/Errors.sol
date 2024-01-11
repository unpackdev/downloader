//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

error NotADeployer();
error BalanceQueryForTheZeroAddress();
error AccountsAndIdsLengthMismatch();
error CallerIsNotOwnerNorApproved();
error IdsAndAmountsLengthMismatch();
error TransferToTheZeroAddress();
error InsufficientBalanceForTransfer();
error MintToTheZeroAddress();
error BurnFromTheZeroAddress();
error BurnAmountExceedsBalance();
error SettingApprovalStatusForSelf();
error ERC1155ReceiverRejectedTokens();
error TransferToNonERC1155ReceiverImplementer();
error NotAllowed();
error UnknownTokenId();
error InsufficientTotalSupplyForDecrease();
error ContractAddressIsNotAContract();
error NotEnoughFunds();
error NotEnoughStock();
error NotOnSale();
error ExhaustedWalletAllowance();
error NotInWhitelist();
