// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SimpleReadAccessController.sol";
import "./AggregatorV2V3Interface.sol";
import "./SignedSafeMath.sol";
import "./SafeMath.sol";
import "./VinciCollectPriceCumulative.sol";

contract CollectAggregator is AggregatorV2V3Interface, SimpleReadAccessController {
    struct Round {
      int256 answer;
      uint64 startedAt;
      uint64 updatedAt;
      uint32 answeredInRound;
    }

    uint32 internal latestRoundId;
    mapping(uint32 => Round) internal rounds;

    uint8 public override decimals;
    string public override description;

    int256 immutable public minSubmissionValue;
    int256 immutable public maxSubmissionValue;

    uint256 constant public override version = 3;

    uint32 constant private ROUND_MAX = 2**32-1;
    // An error specific to the Aggregator V3 Interface, to prevent possible
    // confusion around accidentally reading unset values as reported values.
    string constant private V3_NO_DATA_ERROR = "No data present";

    address private _operator;
    address private _collector;
    uint64 private timeInterval;

    int256 priceCumulative;
    uint64 latestTimeAt;

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
      uint64 _timeInterval,
      string memory _description
    ) {
      minSubmissionValue = _minSubmissionValue;
      maxSubmissionValue = _maxSubmissionValue;
      decimals = _decimals;
      description = _description;
      timeInterval = _timeInterval;
      rounds[0].updatedAt = uint64(block.timestamp - (uint256(_timeout)));
    }

    function computeAmountOut() private view returns (int256 amountOut, int256 currentPriceCumulative, uint64 currentTime) {
      require(_collector != address(0), "Please set the collector first");

      (currentPriceCumulative, currentTime) = CollectInterface(_collector).getPriceCumulative();
      int256 timeElapsed = int256(SafeMath.sub(currentTime, latestTimeAt));
      int256 priceDifference = SignedSafeMath.sub(currentPriceCumulative, priceCumulative);
      amountOut = SignedSafeMath.div(priceDifference, timeElapsed);
    }

    /**
      * Receive the response in the form of uint256
      */ 
    function submit(int256 _data) public onlyOwner
    {
      require(_data >= minSubmissionValue, "value below minSubmissionValue");
      require(_data <= maxSubmissionValue, "value above maxSubmissionValue");

      uint64 startedAt = uint64(block.timestamp); 
      updateRoundAnswer(latestRoundId + 1, startedAt, _data);
    }

    function submitWithTWAP() public
    {
      int256 data;
      (data, priceCumulative, latestTimeAt)= computeAmountOut();
      updateRoundAnswer(latestRoundId + 1, uint64(block.timestamp), data);
    }

    function setCollector(address _address) public onlyOwner {
      _collector = _address;
    }

    function getCollector() public view returns (address) {
      return _collector;
    }

    function setTimesInterval(uint64 _timeInterval) public onlyOwner {
      timeInterval = _timeInterval;
    }

    function getTimesInterval() public view returns (uint64) {
      return timeInterval;
    }

    /**
    * @notice get the most recently reported answer
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestAnswer()
      public
      view
      virtual
      override
      returns (int256)
    {
      return rounds[latestRoundId].answer;
    }

    /**
    * @notice get the most recent updated at timestamp
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestTimestamp()
      public
      view
      virtual
      override
      returns (uint256)
    {
      return rounds[latestRoundId].updatedAt;
    }

    /**
    * @notice get the ID of the last updated round
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestRound()
      public
      view
      virtual
      override
      returns (uint256)
    {
      return latestRoundId;
    }

    /**
    * @notice get past rounds answers
    * @param _roundId the round number to retrieve the answer for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getAnswer(uint256 _roundId)
      public
      view
      virtual
      override
      returns (int256)
    {
      if (validRoundId(_roundId)) {
        return rounds[uint32(_roundId)].answer;
      }
      return 0;
    }

    /**
    * @notice get timestamp when an answer was last updated
    * @param _roundId the round number to retrieve the updated timestamp for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getTimestamp(uint256 _roundId)
      public
      view
      virtual
      override
      returns (uint256)
    {
      if (validRoundId(_roundId)) {
        return rounds[uint32(_roundId)].updatedAt;
      }
      return 0;
    }

    /**
    * @notice get data about a round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values.
    * @param _roundId the round ID to retrieve the round data for
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answeredInRound is equal to roundId when the round didn't time out
    * and was completed regularly.
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet received
    * maxSubmissions) answer and updatedAt may change between queries.
    */
    function getRoundData(uint80 _roundId)
      public
      view
      virtual
      override
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      )
    {
      Round memory r = rounds[uint32(_roundId)];

      require(r.answeredInRound > 0 && validRoundId(_roundId), V3_NO_DATA_ERROR);

      return (
        _roundId,
        r.answer,
        r.startedAt,
        r.updatedAt,
        r.answeredInRound
      );
    }

    /**
    * @notice get data about the latest round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values. Consumers are encouraged to
    * use this more fully featured method over the "legacy" latestRound/
    * latestAnswer/latestTimestamp functions. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values.
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answeredInRound is equal to roundId when the round didn't time
    * out and was completed regularly.
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
    * received maxSubmissions) answer and updatedAt may change between queries.
    */
    function latestRoundData()
      public
      view
      virtual
      override
      returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
    {
      return getRoundData(latestRoundId);
    }

    function updateRoundAnswer(uint32 _roundId, uint64 _startedAt, int256 _newAnswer)
      internal
    {
      require(timeInterval <= SafeMath.sub(_startedAt, latestTimestamp()), "No repeated feeding during the minimum interval");

      rounds[_roundId].answer = _newAnswer;
      rounds[_roundId].startedAt = _startedAt;
      rounds[_roundId].updatedAt = uint64(block.timestamp);
      rounds[_roundId].answeredInRound = _roundId;
      latestRoundId = _roundId;

      emit AnswerUpdated(_newAnswer, _roundId, block.timestamp);
    }

    function validRoundId(uint256 _roundId)
      private
      pure
      returns (bool)
    {
      return _roundId <= ROUND_MAX;
    }
}


contract VinciCollectAggregator is CollectAggregator {
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
      uint64 _timeInterval,
      string memory _description
    ) CollectAggregator(
      _timeout,
      _minSubmissionValue,
      _maxSubmissionValue,
      _decimals,
      _timeInterval,
      _description
    ){}

    /**
    * @notice get data about a round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values.
    * @param _roundId the round ID to retrieve the round data for
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answerInRound is equal to roundId when the round didn't time out
    * and was completed regularly.
    * @dev overridden funcion to add the checkAccess() modifier
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
    * received maxSubmissions) answer and updatedAt may change between queries.
    */
    function getRoundData(uint80 _roundId)
      public
      view
      override
      checkAccess()
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      )
    {
      return super.getRoundData(_roundId);
    }

    /**
    * @notice get data about the latest round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values. Consumers are encouraged to
    * use this more fully featured method over the "legacy" latestAnswer
    * functions. Consumers are encouraged to check that they're receiving fresh
    * data by inspecting the updatedAt and answeredInRound return values.
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answerInRound is equal to roundId when the round didn't time out
    * and was completed regularly.
    * @dev overridden funcion to add the checkAccess() modifier
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
    * received maxSubmissions) answer and updatedAt may change between queries.
    */
    function latestRoundData()
      public
      view
      override
      checkAccess()
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      )
    {
      return super.latestRoundData();
    }

    /**
    * @notice get the most recently reported answer
    * @dev overridden funcion to add the checkAccess() modifier
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestAnswer()
      public
      view
      override
      checkAccess()
      returns (int256)
    {
      return super.latestAnswer();
    }

    /**
    * @notice get the most recently reported round ID
    * @dev overridden funcion to add the checkAccess() modifier
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestRound()
      public
      view
      override
      checkAccess()
      returns (uint256)
    {
      return super.latestRound();
    }

    /**
    * @notice get the most recent updated at timestamp
    * @dev overridden funcion to add the checkAccess() modifier
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestTimestamp()
      public
      view
      override
      checkAccess()
      returns (uint256)
    {

      return super.latestTimestamp();
    }

    /**
    * @notice get past rounds answers
    * @dev overridden funcion to add the checkAccess() modifier
    * @param _roundId the round number to retrieve the answer for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getAnswer(uint256 _roundId)
      public
      view
      override
      checkAccess()
      returns (int256)
    {
      return super.getAnswer(_roundId);
    }

    /**
    * @notice get timestamp when an answer was last updated
    * @dev overridden funcion to add the checkAccess() modifier
    * @param _roundId the round number to retrieve the updated timestamp for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getTimestamp(uint256 _roundId)
      public
      view
      override
      checkAccess()
      returns (uint256)
    {
      return super.getTimestamp(_roundId);
    }

}
