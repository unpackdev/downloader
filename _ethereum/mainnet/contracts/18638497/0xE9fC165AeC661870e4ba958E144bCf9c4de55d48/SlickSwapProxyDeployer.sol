// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * SlickSwap Proxy Deployer
 *
 * This is a factory contract which deploys proxy contracts to be used as individual SlickSwap contract wallets.
 *
 * All proxies have identical bytecode, but are initialized with the logic contract address stored in the
 * EIP-1967 implementation slot (see IMPLEMENTATION_SLOT) that makes the implementation discoverable by block explorers.
 *
 * Logic contract address in storage allows contract upgrades; see specific implementation for exact conditions.
 */
contract SlickSwapProxyDeployer {
  // EIP-1967 defines implementation slot as uint256(keccak256('eip1967.proxy.implementation')) - 1
  bytes32 constant IMPLEMENTATION_SLOT = hex'360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';

  /**
   * Deploy a new proxy contract with a deterministic address (see computeProxyAddress())
   *
   * @param salt arbitrary 256-bits of entropy provided by the deployer
   * @param implAddr the logic contract address (contains code to delegatecall)
   * @param constructorCalldata the calldata for a "constructor" method to call right away
   */
  function deployProxy(bytes32 salt, address implAddr, bytes calldata constructorCalldata) external {
    // deterministic proxy address
    address proxyAddress;

    // proxy creation code instance
    bytes memory initCodeInst = initCode(implAddr);

    // directly invoking CREATE2 unfortunately still requires assembly in 0.8.20^
    assembly {
      // "bytes memory" is laid out in memory as:
      //   1) mload(initCodeInst)     - 32 byte length
      //   2) add(initCodeInst, 0x20) - a byte array
      proxyAddress := create2(0, add(initCodeInst, 0x20), mload(initCodeInst), salt)

      if iszero(extcodesize(proxyAddress)) {
        revert(0, 0)
      }
    }

    // call the constructor immediately
    (bool success,) = proxyAddress.call(constructorCalldata);
    require(success, "Proxy constructor reverted.");
  }

  /**
   * A way to predict the address of a proxy deployed with specific salt, owner & logic addresses.
   *
   * @param salt arbitrary 256-bits of entropy provided by the deployer
   * @param implAddr the logic contract address (contains code to delegatecall)
   *
   * @return the proxy deterministic address
   */
  function computeProxyAddress(bytes32 salt, address implAddr) external view returns (address) {
    // first compute the init code hash (it's different every time due to owner & impl addresses)
    bytes32 initCodeHash = keccak256(initCode(implAddr));

    // then we may predict the EIP-1014 CREATE2 address
    return address(uint160(uint256(keccak256(abi.encodePacked(hex'ff', this, salt, initCodeHash)))));
  }

  /**
   * Returns contract bytecode to be used with CREATE2. The bytecode is obtained by compiling SlickSwapProxy contract
   * using solc version 0.8.23+commit.f704f362 with optimizer turned off and evmVersion set to "shanghai".
   *
   * Please refer to any contract created by this factory to see the full source code used to produce the below bytecode.
   *
   * @param implAddr the logic contract address (contains code to delegatecall)
   *
   * @return the proxy initcode
   */
  function initCode(address implAddr) internal pure returns (bytes memory) {
    return abi.encodePacked(
      // creation time bytecode
      hex'6080604052348015600e575f80fd5b5073', implAddr, hex'7f', IMPLEMENTATION_SLOT, hex'556050806100525f395ff3fe'

      // deployed proxy bytecode
      hex'6080604052365f80375f80365f7f', IMPLEMENTATION_SLOT, hex'545af43d5f803e805f8114603f573d5ff35b3d5ffdfea164736f6c6343000817000a'
    );
  }
}
