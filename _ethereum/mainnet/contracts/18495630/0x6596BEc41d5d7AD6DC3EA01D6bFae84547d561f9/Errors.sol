// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

///@title Errors
///@notice Defines the different errors of Gamma Address contracts
library Errors {
  /// @notice Function was not called by owner.
  string public constant OWNABLE_NOT_OWNER = "OWNABLE_NOT_OWNER";
  /// @notice Function was not called by the NFT address owner.
  string public constant ERC721_NOT_TOKEN_OWNER = "ERC721_NOT_TOKEN_OWNER";
  /// @notice Factory can't be used to mint an NFT address.
  string public constant UNAUTHORIZED_FACTORY = "UNAUTHORIZED_FACTORY";
  /// @notice ETH value insufficient to mint an NFT address. See `Registrar._mintPrice` value.
  string public constant INSUFFICIENT_MINT_PAYMENT = "INSUFFICIENT_MINT_PAYMENT";
  /// @notice Contract's balance is less than the requested amount to withdraw.
  string public constant INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS";
  /// @notice Transfer failed.
  string public constant TRANSFER_FAILED = "TRANSFER_FAILED";
  /// @notice The NFT address can't be minted because it already exists.
  string public constant ADDRESS_ALREADY_MINTED = "ADDRESS_ALREADY_MINTED";
  /// @notice Function was not called by the Registrar.
  string public constant NOT_REGISTRAR = "NOT_REGISTRAR";
  /// @notice Deployment problem. The smart contract was not deployed to the correct address.
  string public constant INVALID_ADDRESS_CREATED = "INVALID_ADDRESS_CREATED";
  /// @notice Royalties should be 100%(10000 basis points) or less.
  string public constant INVALID_ROYALTIES = "INVALID_ROYALTIES";
  /// @notice Sender doesn't have deploy permission
  string public constant NO_DEPLOY_PERMISSION = "NO_DEPLOY_PERMISSION";
}
