// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Minimal Permit2 interface, derived from
// https://github.com/Uniswap/permit2/blob/main/src/interfaces/ISignatureTransfer.sol
interface IPermit2 {
  struct TokenPermissions {
    address token;
    uint256 amount;
  }

  struct PermitTransferFrom {
    TokenPermissions permitted;
    uint256 nonce;
    uint256 deadline;
  }

  struct PermitBatchTransferFrom {
    TokenPermissions[] permitted;
    uint256 nonce;
    uint256 deadline;
  }

  struct SignatureTransferDetails {
    address to;
    uint256 requestedAmount;
  }

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function permitTransferFrom(
    PermitTransferFrom calldata permit,
    SignatureTransferDetails calldata transferDetails,
    address owner,
    bytes calldata signature
  )
    external;

  function permitTransferFrom(
    PermitBatchTransferFrom memory permit,
    SignatureTransferDetails[] calldata transferDetails,
    address owner,
    bytes calldata signature
  )
    external;
}
