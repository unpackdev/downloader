// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./VotingInterface.sol";

library VoteTiming {
  using SafeMath for uint256;

  struct Data {
    uint256 phaseLength;
  }

  function init(Data storage data, uint256 phaseLength) internal {
    require(phaseLength > 0);
    data.phaseLength = phaseLength;
  }

  function computeCurrentRoundId(Data storage data, uint256 currentTime)
    internal
    view
    returns (uint256)
  {
    uint256 roundLength =
      data.phaseLength.mul(
        uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER)
      );
    return currentTime.div(roundLength);
  }

  function computeRoundEndTime(Data storage data, uint256 roundId)
    internal
    view
    returns (uint256)
  {
    uint256 roundLength =
      data.phaseLength.mul(
        uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER)
      );
    return roundLength.mul(roundId.add(1));
  }

  function computeCurrentPhase(Data storage data, uint256 currentTime)
    internal
    view
    returns (VotingAncillaryInterface.Phase)
  {
    return
      VotingAncillaryInterface.Phase(
        currentTime.div(data.phaseLength).mod(
          uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER)
        )
      );
  }
}
