pragma solidity ^0.8.20;

// SPDX-License-Identifier: MIT

/**
 * SlickSwap Proxy Deployer
 *
 * This is a factory contract which deploys minimal (58 bytes in size) proxy contracts to
 * be used as individual SlickSwap contract wallets.
 *
 * All proxies have identical bytecode, but are initialized with the logic contract address stored in the
 * EIP-1967 implementation slot (see IMPL_SLOT) that makes the implementation discoverable by block explorers.
 *
 * Logic contract address in storage allows contract upgrades; see specific implementation for exact conditions.
 *
 * Proxy bytecode is almost identical to EIP-1167 Minimal Proxy Contract (again, see initCode() below for details). The DELEGATECALL
 * logic is fully transparent - calldata gets forwarded to the logic contract as-is, return data is unaltered as well.
 */
contract SlickSwapProxyDeployer {
  // EIP-1967 defines implementation slot as uint256(keccak256('eip1967.proxy.implementation')) - 1
  bytes32 constant IMPL_SLOT = hex'360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';

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
   * Hand-written init code (total size 122 bytes):
   *
   *  === Creation time bytecode (64 bytes, parameterized by implAddr) ===
   *
   *  Offset         Bytecode            Opcode               Stack after               Comment
   *
   *  00..14           73 <20 bytes>     PUSH20 <implAddr>    implAddr
   *  15..35           7F <32 bytes>     PUSH32 <implSlot>    implSlot implAddr
   *  36               55                SSTORE                                         Store implementation address into EIP-1967 slot
   *  37..38           60 3A             PUSH1 <bcSz>         bcSz                      bcSz = 58 (0x3A)
   *  39               80                DUP1                 bcSz bcSz
   *  3A..3B           60 40             PUSH1 <bcOffs>       bcOffs bcSz bcSz          bc0ffs = 64 (0x40)
   *  3C               3D                RETURNDATASIZE       0 bcOffs bcSz bcSz        EIP-211 zero trick
   *  3D               39                CODECOPY             bcSz                      mem[0:bcSz] := code[bcOffs:bcOffs+bcSz]
   *  3E               3D                RETURNDATASIZE       0 bcSz
   *  3F               F3                RETURN                                         mem[0:bcSz] - returns proxy bytecode
   *
   *  === Deployed proxy bytecode (58 bytes, identical for all proxies) ===
   *
   *  Offset  (-0x40)  Bytecode          Opcode               Stack after               Comment
   *
   *  40      00       36                CALLDATASIZE         cds
   *  41      01       3D                RETURNDATASIZE       0 cds                     EIP-211 zero trick
   *  42      02       3D                RETURNDATASIZE       0 0 cds
   *  43      03       37                CALLDATACOPY                                   mem[0:cds] = calldata
   *  44      04       3D                RETURNDATASIZE       0
   *  45      05       3D                RETURNDATASIZE       0 0
   *  46      06       3D                RETURNDATASIZE       0 0 0
   *  47      07       36                CALLDATASIZE         cds 0 0 0
   *  48      08       3D                RETURNDATASIZE       0 cds 0 0 0
   *  49..69  09..29   7F <32 bytes>     PUSH32 <implSlot>    implSlot 0 cds 0 0 0
   *  6A      2A       54                SLOAD                implAddr 0 cds 0 0 0      Read implAddr from EIP-1967 slot
   *  6B      2B       5A                GAS                  gas implAddr 0 cds 0 0 0
   *  6C      2C       F4                DELEGATECALL         suc 0                     Delegatecall implAddr with full calldata and gas
   *  6D      2D       3D                RETURNDATASIZE       rds suc 0                 NB: EIP-211 zero trick doesn't work anymore
   *  6E      2E       82                DUP3                 0 rds suc 0
   *  6F      2F       80                DUP1                 0 0 rds suc 0
   *  70      30       3E                RETURNDATACOPY       suc 0                     mem[0:rds] := returndata[0:rds]
   *  71      31       90                SWAP1                0 suc
   *  72      32       3D                RETURNDATASIZE       rds 0 suc
   *  73      33       91                SWAP2                suc 0 rds
   *  74..75  34..35   60 38             PUSH1 :success:      :success: suc 0 rds
   *  76      36       57                JUMPI                0 rds                     jumps to :success: if suc != 0
   *  77      37       FD                REVERT
   *  78      38       5B                JUMPDEST                                       :success: label
   *  79      39       F3                RETURN
   *
   * NB: Proxy bytecode is identical to EIP-1167 Minimal Proxy Contract with two changes - instead of pushing implAddr on stack
   *     directly we load it from storage at EIP-1967 slot (offsets 09..2A), and adjusted jump destination (offset 35). These changes
   *     were introduced to support individual upgradeability and resulted in proxy size being inflated from 44 bytes to 58 bytes.
   *
   * @param implAddr the logic contract address (contains code to delegatecall)
   *
   * @return the proxy initcode
   */
  function initCode(address implAddr) internal pure returns (bytes memory) {
    return abi.encodePacked(
      // creation time bytecode
      hex'73', implAddr, hex'7f', IMPL_SLOT, hex'55603A8060403d393df3',
      // deployed proxy bytecode
      hex'363d3d373d3d3d363d7f', IMPL_SLOT, hex'545af43d82803e903d91603857fd5bf3'
    );
  }
}
