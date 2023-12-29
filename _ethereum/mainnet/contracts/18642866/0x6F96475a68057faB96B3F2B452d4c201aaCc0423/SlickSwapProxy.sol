// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * SlickSwap Proxy
 *
 * A pretty minimal implementation of EIP-1967 proxy contract which simply forwards all calls to
 * the logic contract.
 *
 * Please use Read as Proxy / Write as Proxy on etherscan.io to interact with the wallet.
 */
contract SlickSwapProxy {
  // Initial SlickSwap implementation address (might change during upgrades)
  address constant internal IMPLEMENTATION_ADDRESS = 0xC887bE361b98b73Fc5Ad7F221964b1518d9e0f23;
  // EIP-1967 slot storing implementation address.
  bytes32 constant internal IMPLEMENTATION_SLOT = hex'360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';

  /**
   * Initializes the contract by storing the current address into implementation slot.
   */
  constructor() {
    assembly {
      sstore(IMPLEMENTATION_SLOT, IMPLEMENTATION_ADDRESS)
    }
  }

  /**
   * Catch-all fallback function that invokes logic's method via delegatecall(), which makes the logic
   * use this contract's storage yet run implementation's logic.
   */
  fallback() external payable {
    assembly {
      calldatacopy(0, 0, calldatasize())

      let result := delegatecall(gas(), sload(IMPLEMENTATION_SLOT), 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}
