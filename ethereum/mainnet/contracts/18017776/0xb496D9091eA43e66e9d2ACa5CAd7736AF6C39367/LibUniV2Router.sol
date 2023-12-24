// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IUniswapV2Router02.sol";
import "./IWETH.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibUniV2Router {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256('diamond.storage.LibUniV2Router');

  struct DiamondStorage {
    bool isInitialized;
    IWETH weth;
    IUniswapV2Router02 uniswapV2router02;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage s) {
    bytes32 position = DIAMOND_STORAGE_POSITION;

    assembly {
      s.slot := position
    }
  }
}
