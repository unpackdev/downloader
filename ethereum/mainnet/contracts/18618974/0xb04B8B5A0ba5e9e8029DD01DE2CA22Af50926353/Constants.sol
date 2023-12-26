// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

/// @title Constants
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Constants for constructing onchain Together NFT
contract Constants {
  uint256 public constant PRICE = 0.01 ether;

  address payable internal constant _VAULT_ADDRESS = payable(address(0x39Ab90066cec746A032D67e4fe3378f16294CF6b));
  address internal constant _XXYYZZ_TOKEN_ADDRESS = address(0xFf6000a85baAc9c4854fAA7155e70BA850BF726b);
  uint8 internal constant _MINT_AMOUNT_DURING_COMMENCE = 5;
  uint8 internal constant _MAX_PUBLIC_MINT_AMOUNT_PER_TRANSACTION = 5;
}
