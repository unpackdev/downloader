// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Address.sol";
import "./FullMath.sol";

library SafeCall {
  using Address for address;
  using Address for address payable;

  function safeCall(address target, bytes memory data) internal returns (bool, bytes memory) {
    return safeCall(payable(target), data, 0);
  }

  function safeCall(
    address payable target,
    bytes memory data,
    uint256 value
  ) internal returns (bool, bytes memory) {
    return safeCall(target, data, value, 0);
  }

  function safeCall(
    address payable target,
    bytes memory data,
    uint256 value,
    uint256 depth
  ) internal returns (bool success, bytes memory returndata) {
    require(depth < 42, "SafeCall: overflow");
    if (value > 0 && (address(this).balance < value || !target.isContract())) {
      return (success, returndata);
    }

    uint256 beforeGas;
    uint256 afterGas;

    assembly ("memory-safe") {
      // As of the time this contract was written, `verbatim` doesn't work in
      // inline assembly. Due to how the Yul IR optimizer inlines and optimizes,
      // the amount of gas required to prepare the stack with arguments for call
      // is unpredictable. However, each these operations cost
      // gas. Additionally, `call` has an intrinsic gas cost, which is too
      // complicated for this comment but can be found in the Ethereum
      // yellowpaper, Berlin version fabef25, appendix H.2, page 37. Therefore,
      // `beforeGas` is always above the actual gas available before the
      // all-but-one-64th rule is applied. This makes the following checks too
      // conservative. We do not correct for any of this because the correction
      // would become outdated (possibly too permissive) if the opcodes are
      // repriced.

      let offset := add(data, 0x20)
      let length := mload(data)
      beforeGas := gas()
      success := call(gas(), target, value, offset, length, 0, 0)

      // Assignment of a value to a variable costs gas (although how much is
      // unpredictable because it depends on the optimizer), as does the `GAS`
      // opcode itself. Therefore, the `gas()` below returns less than the
      // actual amount of gas available for computation at the end of the
      // call. Again, that makes the check slightly too conservative. Again, we
      // do not attempt any correction.
      afterGas := gas()
    }

    if (!success) {
      // The arithmetic here iterates the all-but-one-sixty-fourth rule to
      // ensure that the call that's `depth` contexts away received enough
      // gas. See: https://eips.ethereum.org/EIPS/eip-150
      unchecked {
        depth++;
        uint256 powerOf64 = 1 << (depth * 6);
        if (FullMath.mulDivCeil(beforeGas, powerOf64 - 63 ** depth, powerOf64) >= afterGas) {
          assembly ("memory-safe") {
            // The call probably failed due to out-of-gas. We deliberately
            // consume all remaining gas with `invalid` (instead of `revert`) to
            // make this failure distinguishable to our caller.
            invalid()
          }
        }
      }
    }

    assembly ("memory-safe") {
      switch returndatasize()
      case 0 {
        returndata := 0x60
        if iszero(value) {
          success := and(success, iszero(iszero(extcodesize(target))))
        }
      }
      default {
        returndata := mload(0x40)
        mstore(returndata, returndatasize())
        let offset := add(returndata, 0x20)
        returndatacopy(offset, 0, returndatasize())
        mstore(0x40, add(offset, returndatasize()))
      }
    }
  }

  function safeStaticCall(address target, bytes memory data) internal view returns (bool, bytes memory) {
    return safeStaticCall(target, data, 0);
  }

  function safeStaticCall(
    address target,
    bytes memory data,
    uint256 depth
  ) internal view returns (bool success, bytes memory returndata) {
    require(depth < 42, "SafeCall: overflow");

    uint256 beforeGas;
    uint256 afterGas;

    assembly ("memory-safe") {
      // As of the time this contract was written, `verbatim` doesn't work in
      // inline assembly. Due to how the Yul IR optimizer inlines and optimizes,
      // the amount of gas required to prepare the stack with arguments for call
      // is unpredictable. However, each these operations cost
      // gas. Additionally, `staticcall` has an intrinsic gas cost, which is too
      // complicated for this comment but can be found in the Ethereum
      // yellowpaper, Berlin version fabef25, appendix H.2, page 37. Therefore,
      // `beforeGas` is always above the actual gas available before the
      // all-but-one-64th rule is applied. This makes the following checks too
      // conservative. We do not correct for any of this because the correction
      // would become outdated (possibly too permissive) if the opcodes are
      // repriced.

      let offset := add(data, 0x20)
      let length := mload(data)
      beforeGas := gas()
      success := staticcall(gas(), target, offset, length, 0, 0)

      // Assignment of a value to a variable costs gas (although how much is
      // unpredictable because it depends on the optimizer), as does the `GAS`
      // opcode itself. Therefore, the `gas()` below returns less than the
      // actual amount of gas available for computation at the end of the
      // call. Again, that makes the check slightly too conservative. Again, we
      // do not attempt any correction.
      afterGas := gas()
    }

    if (!success) {
      // The arithmetic here iterates the all-but-one-sixty-fourth rule to
      // ensure that the call that's `depth` contexts away received enough
      // gas. See: https://eips.ethereum.org/EIPS/eip-150
      unchecked {
        depth++;
        uint256 powerOf64 = 1 << (depth * 6);
        if (FullMath.mulDivCeil(beforeGas, powerOf64 - 63 ** depth, powerOf64) >= afterGas) {
          assembly ("memory-safe") {
            // The call probably failed due to out-of-gas. We deliberately
            // consume all remaining gas with `invalid` (instead of `revert`) to
            // make this failure distinguishable to our caller.
            invalid()
          }
        }
      }
    }

    assembly ("memory-safe") {
      switch returndatasize()
      case 0 {
        returndata := 0x60
        success := and(success, iszero(iszero(extcodesize(target))))
      }
      default {
        returndata := mload(0x40)
        mstore(returndata, returndatasize())
        let offset := add(returndata, 0x20)
        returndatacopy(offset, 0, returndatasize())
        mstore(0x40, add(offset, returndatasize()))
      }
    }
  }
}
