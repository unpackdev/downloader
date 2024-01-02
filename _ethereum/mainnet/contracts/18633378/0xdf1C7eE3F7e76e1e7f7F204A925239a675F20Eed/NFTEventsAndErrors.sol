// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

interface NFTEventsAndErrors {
  error AlreadyCommenced();
  error PublicMintNotEnabled();
  error AllowListMintCapPerWalletExceeded();
  error AllowListMintCapExceeded();
  error PublicMintMaxPerTransactionExceeded();
  error MintNotStarted();
  error MaxSupplyReached();
  error IncorrectPayment();
  error MsgSenderDoesNotOwnXXYYZZToken();
  error MsgSenderNotTokenOwner();
  event MetadataUpdate(uint256 tokenId);
}
