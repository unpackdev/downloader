// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SignedSafeMath.sol";
import "./SafeMath.sol";
import "./Operatable.sol";
import "./CollectInterface.sol";

contract VinciCollectPriceCumulative is CollectInterface, Operatable {
    
    int256 priceCumulative;
    uint64 latestUpdatedAt;

    uint8 public decimals;
    string public description;

    int256 immutable public minSubmissionValue;
    int256 immutable public maxSubmissionValue;

    uint256 constant public version = 1;
    address private _operator;

    /**
    * @notice set up the aggregator with initial configuration
    * @param _timeout is the number of seconds after the previous round that are
    * allowed to lapse before allowing an oracle to skip an unfinished round
    * @param _minSubmissionValue is an immutable check for a lower bound of what
    * submission values are accepted from an oracle
    * @param _maxSubmissionValue is an immutable check for an upper bound of what
    * submission values are accepted from an oracle
    * @param _decimals represents the number of decimals to offset the answer by
    * @param _description a short description of what is being reported
    */
    constructor(
      uint32 _timeout,
      int256 _minSubmissionValue,
      int256 _maxSubmissionValue,
      uint8 _decimals,
      string memory _description
    ) {
      minSubmissionValue = _minSubmissionValue;
      maxSubmissionValue = _maxSubmissionValue;
      decimals = _decimals;
      description = _description;
      latestUpdatedAt = uint64(block.timestamp - (uint256(_timeout)));
    }

    function computeAmountOut(int256 _price, uint64 _startedAt) internal view returns (int256 priceCumulativeOut) {
      int256 timeElapsed = int256(SafeMath.sub(_startedAt, latestUpdatedAt));
      priceCumulativeOut = SignedSafeMath.mul(_price, timeElapsed);
      priceCumulativeOut = SignedSafeMath.add(priceCumulativeOut, priceCumulative);
    }

    /**
      * Receive the response in the form of uint256
      */ 
    function updatePriceCumulative(int256 _data) public onlyOperator {
      require(_data >= minSubmissionValue, "value below minSubmissionValue");
      require(_data <= maxSubmissionValue, "value above maxSubmissionValue");

      uint64 startedAt = uint64(block.timestamp);
      priceCumulative = computeAmountOut(_data, startedAt);
      latestUpdatedAt = startedAt;
    }

    function getPriceCumulative() public view override returns (int256, uint64) {
      return (priceCumulative, latestUpdatedAt);
    }
}
