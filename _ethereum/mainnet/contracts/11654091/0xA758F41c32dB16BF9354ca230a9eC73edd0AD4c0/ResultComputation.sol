// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./FixedPoint.sol";

library ResultComputation {
  using FixedPoint for FixedPoint.Unsigned;

  struct Data {
    mapping(int256 => FixedPoint.Unsigned) voteFrequency;
    FixedPoint.Unsigned totalVotes;
    int256 currentMode;
  }

  function addVote(
    Data storage data,
    int256 votePrice,
    FixedPoint.Unsigned memory numberTokens
  ) internal {
    data.totalVotes = data.totalVotes.add(numberTokens);
    data.voteFrequency[votePrice] = data.voteFrequency[votePrice].add(
      numberTokens
    );
    if (
      votePrice != data.currentMode &&
      data.voteFrequency[votePrice].isGreaterThan(
        data.voteFrequency[data.currentMode]
      )
    ) {
      data.currentMode = votePrice;
    }
  }

  function getResolvedPrice(
    Data storage data,
    FixedPoint.Unsigned memory minVoteThreshold
  ) internal view returns (bool isResolved, int256 price) {
    FixedPoint.Unsigned memory modeThreshold =
      FixedPoint.fromUnscaledUint(50).div(100);

    if (
      data.totalVotes.isGreaterThan(minVoteThreshold) &&
      data.voteFrequency[data.currentMode].div(data.totalVotes).isGreaterThan(
        modeThreshold
      )
    ) {
      isResolved = true;
      price = data.currentMode;
    } else {
      isResolved = false;
    }
  }

  function wasVoteCorrect(Data storage data, bytes32 voteHash)
    internal
    view
    returns (bool)
  {
    return voteHash == keccak256(abi.encode(data.currentMode));
  }

  function getTotalCorrectlyVotedTokens(Data storage data)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    return data.voteFrequency[data.currentMode];
  }
}
