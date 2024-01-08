// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ========== External Interfaces ========== */
import "./Ownable.sol";

/* ========== External Libraries ========== */
import "./SafeMath.sol";

/* ========== Internal Interfaces ========== */
import "./IScoringStrategy.sol";
import "./ICirculatingMarketCapOracle.sol";


contract ScoreByCMCPegged20 is Ownable, IScoringStrategy {
  using SafeMath for uint256;

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
    require(tokens.length >= 5, "Not enough tokens");
    uint256[] memory marketCaps = ICirculatingMarketCapOracle(circulatingMarketCapOracle).getCirculatingMarketCaps(tokens);
    uint256[] memory positions = sortAndReturnPositions(marketCaps);
    uint256 subscore = calculateIndexSum(marketCaps, positions);
    uint256 len = positions.length;
    scores = new uint256[](len);
    scores[positions[0]] = peggedScore(subscore);
    scores[positions[1]] = peggedScore(subscore);
    for (uint i = 2; i < 5; i++) {
      scores[positions[i]] = downscaledScore(marketCaps[i]);
    }
    for (uint256 j = 5; j < len; j++) {
      scores[positions[j]] = 0;
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
  
  /**
   * @dev Returns the sum of the third, fourth and fifth highest market caps.
   * If WETH and WBTC are included, they're always going to be the top two, and we only want three others.
   * Require statement unnecessary: already included in caller function getTokenScores
   **/
  function calculateIndexSum(uint256[] memory marketCaps, uint256[] memory positions) internal pure returns(uint256 subtotal) {
    for (uint256 i = 2; i < 5; i++) {
      subtotal += marketCaps[positions[i]];
    }
  }

  /**
   * @dev Given a sum score corresponding to the total CMC of the top three non-WETH/WBTC elements (the three other
   * elements that we want to include), returns a value corresponding to 20% of said sum for pegged weights.
   **/
  function peggedScore(uint256 subscore) internal pure returns(uint256) {
    return (subscore.mul(20)).div(100e18);
  }
  
  /**
   * @dev Given a circulating market cap retrieved via oracle (a component of the result of calculateIndexSum),
   * scale the value down by 60% (the remnant after pegging WETH and WBTC to 20% each).
   **/
  function downscaledScore(uint256 oldScore) internal pure returns(uint256) {
    return (oldScore.mul(60)).div(100e18);
  }

}