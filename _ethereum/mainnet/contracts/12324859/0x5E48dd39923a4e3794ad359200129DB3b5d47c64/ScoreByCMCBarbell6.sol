// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "./Ownable.sol";

import "./IScoringStrategy.sol";
import "./ICirculatingMarketCapOracle.sol";


contract ScoreByCMCBarbell6 is Ownable, IScoringStrategy {
  // Chainlink or other circulating market cap oracle
  address public circulatingMarketCapOracle;

  constructor(address circulatingMarketCapOracle_) public Ownable() {
    circulatingMarketCapOracle = circulatingMarketCapOracle_;
  }

  function getTokenScores(address[] calldata tokens)
    external
    view
    override
    returns (uint256[] memory scores)
  {
    require(tokens.length >= 6, "Not enough tokens");
    uint256[] memory marketCaps = ICirculatingMarketCapOracle(circulatingMarketCapOracle).getCirculatingMarketCaps(tokens);
    uint256[] memory positions = sortAndReturnPositions(marketCaps);
    uint256 len = positions.length;
    scores = new uint256[](len);
    scores[positions[0]] = 25;
    scores[positions[1]] = 15;
    scores[positions[2]] = 10;
    scores[positions[3]] = 10;
    scores[positions[4]] = 15;
    scores[positions[5]] = 25;
    for (uint256 i = 6; i < len; i++) {
      scores[positions[i]] = 0;
    }
  }

  /**
   * @dev Sort a list of market caps and return an array with the index each
   * sorted market cap occupied in the unsorted list.
   *
   * Example: [1, 2, 3] => [2, 1, 0]
   *
   * Note: This modifies the original list.
   */
  function sortAndReturnPositions(uint256[] memory marketCaps) internal pure returns(uint256[] memory positions) {
    uint256 len = marketCaps.length;
    positions = new uint256[](len);
    for (uint256 i = 0; i < len; i++) positions[i] = i;
    for (uint256 i = 0; i < len; i++) {
      uint256 marketCap = marketCaps[i];
      uint256 position = positions[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && marketCaps[j] < marketCap) {
        marketCaps[j + 1] = marketCaps[j];
        positions[j+1] = positions[j];
        j--;
      }
      marketCaps[j+1] = marketCap;
      positions[j+1] = position;
    }
  }

  /**
   * @dev Update the address of the circulating market cap oracle.
   */
  function setCirculatingMarketCapOracle(address circulatingMarketCapOracle_) external onlyOwner {
    circulatingMarketCapOracle = circulatingMarketCapOracle_;
  }
}