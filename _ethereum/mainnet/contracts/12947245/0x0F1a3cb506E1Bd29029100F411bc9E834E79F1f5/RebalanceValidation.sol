// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IAdapterRegistry.sol";
import "./ITokenAdapter.sol";
import "./LowGasSafeMath.sol";
import "./Fraction.sol";



library RebalanceValidation {
  using LowGasSafeMath for uint256;
  using Fraction for uint256;

  function validateSufficientImprovement(
    uint256 currentAPR,
    uint256 newAPR,
    uint256 minImprovement
  ) internal pure {
    require(
      newAPR.sub(currentAPR, "!increased").toFractionE18(currentAPR) >= minImprovement,
      "insufficient improvement"
    );
  }

  function validateProposedWeights(
    uint256[] memory currentWeights,
    uint256[] memory proposedWeights
  ) internal pure {
    uint256 len = currentWeights.length;
    require(proposedWeights.length == len, "bad lengths");
    uint256 _sum;
    for (uint256 i; i < len; i++) {
      uint256 weight = proposedWeights[i];
      _sum = _sum.add(weight);
      if (weight == 0) {
        require(currentWeights[i] == 0, "can not set null weight");
      } else {
        require(weight >= 5e16, "weight < 5%");
      }
    }
    require(_sum == 1e18, "weights != 100%");
  }

  function validateAdaptersAndWeights(
    IAdapterRegistry registry,
    address underlying,
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  ) internal view {
    uint256 len = adapters.length;
    require(weights.length == len, "bad lengths");
    uint256 totalWeight;
    for (uint256 i; i < len; i++) {
      IErc20Adapter adapter = adapters[i];
      require(registry.isApprovedAdapter(address(adapter)), "!approved");
      require(adapter.underlying() == underlying, "bad adapter");
      for (uint256 j = i + 1; j < len; j++) {
        require(address(adapter) != address(adapters[j]), "duplicate adapter");
      }
      uint256 weight = weights[i];
      totalWeight = totalWeight.add(weight);
      require(weight >= 5e16, "weight < 5%");
    }
    require(totalWeight == 1e18, "weights != 100%");
  }
}