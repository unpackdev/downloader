// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./INirnVault.sol";
import "./IAdapterRegistry.sol";


contract BatchRebalancer {
  bytes4 internal constant rebalance = INirnVault.rebalance.selector;
  bytes4 internal constant rebalanceWithNewWeights = INirnVault.rebalanceWithNewWeights.selector;
  bytes4 internal constant rebalanceWithNewAdapters = INirnVault.rebalanceWithNewAdapters.selector;

  IAdapterRegistry public immutable registry;

  constructor(address _registry) {
    registry = IAdapterRegistry(_registry);
  }

  function revertWithReturnData(bytes memory _returnData) internal pure {
    // Taken from BoringCrypto
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) revert("silent revert");

    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    revert(abi.decode(_returnData, (string))); // All that remains is the revert string
  }

  function batchExecuteRebalance(address[] calldata vaults, bytes[] calldata calldatas) external {
    require(msg.sender == tx.origin, "!EOA");
    uint256 len = vaults.length;
    require(calldatas.length == len, "bad lengths");
    for (uint256 i; i < len; i++) {
      INirnVault vault = INirnVault(vaults[i]);
      require(
        registry.vaultsByUnderlying(vault.underlying()) == address(vault),
        "bad vault"
      );
      bytes memory data = calldatas[i];
      bytes4 sig;
      assembly { sig := mload(add(data, 32)) }
      require(
        sig == rebalance ||
        sig == rebalanceWithNewWeights ||
        sig == rebalanceWithNewAdapters,
        "fn not allowed"
      );
      (bool success, bytes memory returnData) = address(vault).call(data);
      if (!success) revertWithReturnData(returnData);
    }
  }
}