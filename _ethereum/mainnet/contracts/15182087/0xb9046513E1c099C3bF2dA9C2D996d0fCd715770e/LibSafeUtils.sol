/// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import "./IERC20.sol";

/// @title Manifold LibSafeUtils
library LibSafeUtils {
  uint256 internal constant PRECISION = (10**18);
  // @custom:maxQty  MAX_QTY: 10B tokens is Maximal amount of tokens
  uint256 internal constant MAX_QTY = (10**28);
  // @custom:maxRate  MAX_RATE: up to 1M tokens per ETH is Maxium Rate
  uint256 internal constant MAX_RATE = (PRECISION * 10**6);
  uint256 internal constant MAX_DECIMALS = 18;
  uint256 internal constant ETH_DECIMALS = 18;
  uint256 internal constant MAX_UINT = 2**256 - 1;
  address internal constant ETH_ADDRESS = address(0x0);

  function precision() internal pure returns (uint256) {
    return PRECISION;
  }

  function max_qty() internal pure returns (uint256) {
    return MAX_QTY;
  }

  function max_rate() internal pure returns (uint256) {
    return MAX_RATE;
  }

  function max_decimals() internal pure returns (uint256) {
    return MAX_DECIMALS;
  }

  function eth_decimals() internal pure returns (uint256) {
    return ETH_DECIMALS;
  }

  function max_uint() internal pure returns (uint256) {
    return MAX_UINT;
  }

  function eth_address() internal pure returns (address) {
    return ETH_ADDRESS;
  }

  /// @notice Retrieve the number of decimals used for a given ERC20 token
  /// @dev As decimals are an optional feature in ERC20, this contract uses `call` to
  /// ensure that an exception doesn't cause transaction failure
  /// @param token the token for which we should retrieve the decimals
  /// @return decimals the number of decimals in the given token
  function getDecimals(address token) internal returns (uint256 decimals) {
    bytes4 functionSig = bytes4(keccak256("decimals()"));

    assembly {
      let ptr := mload(0x40)
      mstore(ptr, functionSig)
      let functionSigLength := 0x04
      let wordLength := 0x20

      let success := call(
        gas(), // Amount of gas
        token, // Address to call
        0, // ether to send
        ptr, // ptr to input data
        functionSigLength, // size of data
        ptr, // where to store output data (overwrite input)
        wordLength // size of output data (32 bytes)
      )

      switch success
      case 0 {
        decimals := 0 // If the token doesn't implement `decimals()`, return 0 as default
      }
      case 1 {
        decimals := mload(ptr) // Set decimals to return data from call
      }
      mstore(0x40, add(ptr, 0x04)) // Reset the free memory pointer to the next known free location
    }
  }

  /// @dev Checks that a given address has its token allowance and balance set above the given amount
  /// @param tokenOwner the address which should have custody of the token
  /// @param tokenAddress the address of the token to check
  /// @param tokenAmount the amount of the token which should be set
  /// @param addressToAllow the address which should be allowed to transfer the token
  /// @return bool true if the allowance and balance is set, false if not
  function tokenAllowanceAndBalanceSet(
    address tokenOwner,
    address tokenAddress,
    uint256 tokenAmount,
    address addressToAllow
  ) internal view returns (bool) {
    return (IERC20(tokenAddress).allowance(tokenOwner, addressToAllow) >=
      tokenAmount &&
      IERC20(tokenAddress).balanceOf(tokenOwner) >= tokenAmount);
  }

  function calcDstQty(
    uint256 srcQty,
    uint256 srcDecimals,
    uint256 dstDecimals,
    uint256 rate
  ) internal pure returns (uint256) {
    if (dstDecimals >= srcDecimals) {
      require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
      return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
    } else {
      require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
      return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
    }
  }

  function calcSrcQty(
    uint256 dstQty,
    uint256 srcDecimals,
    uint256 dstDecimals,
    uint256 rate
  ) internal pure returns (uint256) {
    //source quantity is rounded up. to avoid dest quantity being too low.
    uint256 numerator;
    uint256 denominator;
    if (srcDecimals >= dstDecimals) {
      require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
      numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
      denominator = rate;
    } else {
      require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
      numerator = (PRECISION * dstQty);
      denominator = (rate * (10**(dstDecimals - srcDecimals)));
    }
    return (numerator + denominator - 1) / denominator; //avoid rounding down errors
  }

  function calcDestAmount(
    IERC20 src,
    IERC20 dest,
    uint256 srcAmount,
    uint256 rate
  ) internal returns (uint256) {
    return
      calcDstQty(
        srcAmount,
        getDecimals(address(src)),
        getDecimals(address(dest)),
        rate
      );
  }

  function calcSrcAmount(
    IERC20 src,
    IERC20 dest,
    uint256 destAmount,
    uint256 rate
  ) internal returns (uint256) {
    return
      calcSrcQty(
        destAmount,
        getDecimals(address(src)),
        getDecimals(address(dest)),
        rate
      );
  }

  function calcRateFromQty(
    uint256 srcAmount,
    uint256 destAmount,
    uint256 srcDecimals,
    uint256 dstDecimals
  ) internal pure returns (uint256) {
    require(srcAmount <= MAX_QTY);
    require(destAmount <= MAX_QTY);

    if (dstDecimals >= srcDecimals) {
      require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
      return ((destAmount * PRECISION) /
        ((10**(dstDecimals - srcDecimals)) * srcAmount));
    } else {
      require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
      return ((destAmount * PRECISION * (10**(srcDecimals - dstDecimals))) /
        srcAmount);
    }
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}
