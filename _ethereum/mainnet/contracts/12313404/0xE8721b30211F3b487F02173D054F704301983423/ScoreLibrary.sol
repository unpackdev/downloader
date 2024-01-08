// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ========== External Libraries ========== */
import "./SafeMath.sol";


library ScoreLibrary {
  using SafeMath for uint256;

  // Default total weight for a pool.
  uint256 internal constant WEIGHT_MULTIPLIER = 25e18;

  function computeProportionalAmounts(uint256 total, uint256[] memory scores)
    internal
    pure
    returns(uint256[] memory values)
  {
    uint256 sum;
    uint256 len = scores.length;
    values = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      sum = sum.add(scores[i]);
    }
    uint256 denormalizedSum = sum * 1e18;
    uint256 denormalizedTotal = total * 1e18;
    for (uint256 i = 0; i < len; i++) {
      values[i] = scores[i].mul(denormalizedTotal).div(denormalizedSum);
    }
  }

  function computeDenormalizedWeights(uint256[] memory values)
    internal
    pure
    returns (uint96[] memory weights)
  {
    uint256 sum;
    uint256 len = values.length;
    weights = new uint96[](len);
    for (uint256 i = 0; i < len; i++) {
      sum = sum.add(values[i]);
    }
    for (uint256 i = 0; i < len; i++) {
      weights[i] = _safeUint96(values[i].mul(WEIGHT_MULTIPLIER).div(sum));
    }
  }

  /**
   * @dev Given a list of tokens and their scores, sort by scores
   * in descending order, and filter out the tokens with scores that
   * are not within the min/max bounds provided.
   */
  function sortAndFilter(
    address[] memory tokens,
    uint256[] memory scores,
    uint256 minimumScore,
    uint256 maximumScore
  ) internal pure {
    uint256 len = tokens.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 cap = scores[i];
      address token = tokens[i];
      if (cap > maximumScore || cap < minimumScore) {
        token = tokens[--len];
        cap = scores[len];
        scores[i] = cap;
        tokens[i] = token;
        i--;
        continue;
      }
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < cap) {
        scores[j + 1] = scores[j];
        tokens[j + 1] = tokens[j];
        j--;
      }
      scores[j + 1] = cap;
      tokens[j + 1] = token;
    }
    if (len != tokens.length) {
      assembly {
        mstore(tokens, len)
        mstore(scores, len)
      }
    }
  }

  /**
   * @dev Given a list of tokens and their scores, sort by scores
   * in descending order, and filter out the tokens with scores that
   * are not within the min/max bounds provided.
   * This function also returns the list of removed tokens.
   */
  function sortAndFilterReturnRemoved(
    address[] memory tokens,
    uint256[] memory scores,
    uint256 minimumScore,
    uint256 maximumScore
  ) internal pure returns (address[] memory removed) {
    uint256 removedIndex = 0;
    uint256 len = tokens.length;
    removed = new address[](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 cap = scores[i];
      address token = tokens[i];
      if (cap > maximumScore || cap < minimumScore) {
        removed[removedIndex++] = token;
        token = tokens[--len];
        cap = scores[len];
        scores[i] = cap;
        tokens[i] = token;
        i--;
        continue;
      }
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < cap) {
        scores[j + 1] = scores[j];
        tokens[j + 1] = tokens[j];
        j--;
      }
      scores[j + 1] = cap;
      tokens[j + 1] = token;
    }
    if (len != tokens.length) {
      assembly {
        mstore(tokens, len)
        mstore(scores, len)
        mstore(removed, removedIndex)
      }
    }
  }

  function _safeUint96(uint256 x) internal pure returns (uint96 y) {
    y = uint96(x);
    require(y == x, "ERR_MAX_UINT96");
  }
}