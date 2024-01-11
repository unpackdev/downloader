// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./OracleLibrary.sol";
import "./IOracle.sol";

contract ApeOracle is IOracle {

  function price(address[] memory tokenPath, address[] memory quotePools, uint8 fromDecimals, uint32 period) external override view returns (uint256) {
    require(quotePools.length == tokenPath.length - 1, "ApeOracle: Invalid Params");
    uint256 currentPrice = 10 ** uint256(fromDecimals);
    for (uint i = 0; i < quotePools.length; i++) {
      (int24 tick, uint128 weight) = OracleLibrary.consult(quotePools[i], period);
      OracleLibrary.WeightedTickData[] memory data = new OracleLibrary.WeightedTickData[](1);
      data[0] = OracleLibrary.WeightedTickData(tick, weight);
      int24 twapTick = OracleLibrary.getWeightedArithmeticMeanTick(data);
      currentPrice = OracleLibrary.getQuoteAtTick(int24(twapTick), uint128(currentPrice), tokenPath[i], tokenPath[i + 1]);
    }
    return currentPrice;
  }
  
}

