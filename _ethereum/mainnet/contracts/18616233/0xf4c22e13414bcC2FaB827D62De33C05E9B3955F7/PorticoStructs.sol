// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

import "./IERC20.sol";

type PorticoFlagSet is bytes32;

library PorticoFlagSetAccess {
  // the portico uses one word (32 bytes) to represent a large amount of variables

  // bytes 0-1 is the recipient chain
  function recipientChain(PorticoFlagSet flagset) internal pure returns (uint16 ans) {
    assembly {
      ans := add(byte(0, flagset), shl(8, byte(1, flagset)))
    }
  }

  // bytes 2-5 is the bridge nonce
  function bridgeNonce(PorticoFlagSet flagset) internal pure returns (uint32 ans) {
    assembly {
      ans := add(add(add(byte(2, flagset), shl(8, byte(3, flagset))), shl(16, byte(4, flagset))), shl(24, byte(5, flagset)))
    }
  }

  // bytes 6,7,8 is the fee tier for start path
  function feeTierStart(PorticoFlagSet flagset) internal pure returns (uint24 ans) {
    assembly {
      ans := add(add(byte(6, flagset), shl(8, byte(7, flagset))), shl(16, byte(8, flagset)))
    }
  }

  // bytes 9,10,11 is the fee tier for finish path
  function feeTierFinish(PorticoFlagSet flagset) internal pure returns (uint24 ans) {
    assembly {
      ans := add(add(byte(9, flagset), shl(8, byte(10, flagset))), shl(16, byte(11, flagset)))
    }
  }

  // bytes 12,13 is the max slippage for the start path
  // in BPS - 100 = 1% slippage.
  function maxSlippageStart(PorticoFlagSet flagset) internal pure returns (int16 ans) {
    assembly {
      ans := add(byte(12, flagset), shl(8, byte(13, flagset)))
    }
  }

  // bytes 14,15 is the max slippage for the start path
  // in BPS - 100 = 1% slippage.
  function maxSlippageFinish(PorticoFlagSet flagset) internal pure returns (int16 ans) {
    assembly {
      ans := add(byte(14, flagset), shl(8, byte(15, flagset)))
    }
  }

  // shouldWrapNative is the first bit of the byte 31
  function shouldWrapNative(PorticoFlagSet flagset) internal pure returns (bool) {
    bytes32 fs = PorticoFlagSet.unwrap(flagset);
    return uint8(fs[31]) & (1 << 0) > 0;
  }

  // shouldUnwrapNative is the second bit of byte 31
  function shouldUnwrapNative(PorticoFlagSet flagset) internal pure returns (bool) {
    bytes32 fs = PorticoFlagSet.unwrap(flagset);
    return uint8(fs[31]) & (1 << 1) > 0;
  }
}

library PorticoStructs {
  //16 + 32 + 24 + 24 + 16 + 16 + 8 + 8 == 144
  struct packedData {
    uint16 recipientChain;
    uint32 bridgeNonce;
    uint24 startFee;
    uint24 endFee;
    int16 slipStart;
    int16 slipEnd;
    bool wrap;
    bool unwrap;
  }

  //https://github.com/wormhole-foundation/wormhole-solidity-sdk/blob/main/src/WormholeRelayerSDK.sol#L177
  //https://docs.wormhole.com/wormhole/quick-start/tutorials/hello-token#receiving-a-token
  struct TokenReceived {
    bytes32 tokenHomeAddress;
    uint16 tokenHomeChain;
    IERC20 tokenAddress;
    uint256 amount;
  }

  //268,090 - to beat
  struct TradeParameters {
    PorticoFlagSet flags;
    IERC20 startTokenAddress;
    IERC20 canonAssetAddress;
    IERC20 finalTokenAddress;
    // address of the recipient on the recipientChain
    address recipientAddress;
    // address of the portico on the recipient chain
    address recipientPorticoAddress;
    // the amount of the token that the person wishes to transfer
    uint256 amountSpecified;
    uint256 relayerFee; // the amount of tokens of the recipient to give to the relayer
  }
  //268,041 158,788
  struct DecodedVAA {
    PorticoFlagSet flags;
    IERC20 finalTokenAddress;
    // the person to receive the token
    address recipientAddress;
    // the x asset amount expected to  be received
    uint256 canonAssetAmount;
    uint256 relayerFee;
  }

  struct BridgeInfo {
    IERC20 tokenReceived;
    uint256 amountReceived;
    uint256 relayerFeeAmount;
  }
}
