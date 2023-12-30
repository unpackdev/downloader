/**

  Source code of Opium Protocol On-chain SubIds OracleId
  Web https://opium.network
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// File: opium-contracts/contracts/Interface/IOracleId.sol

pragma solidity 0.5.16;

/// @title Opium.Interface.IOracleId contract is an interface that every oracleId should implement
interface IOracleId {
    /// @notice Requests data from `oracleId` one time
    /// @param timestamp uint256 Timestamp at which data are needed
    function fetchData(uint256 timestamp) external payable;

    /// @notice Requests data from `oracleId` multiple times
    /// @param timestamp uint256 Timestamp at which data are needed for the first time
    /// @param period uint256 Period in seconds between multiple timestamps
    /// @param times uint256 How many timestamps are requested
    function recursivelyFetchData(uint256 timestamp, uint256 period, uint256 times) external payable;

    /// @notice Requests and returns price in ETH for one request. This function could be called as `view` function. Oraclize API for price calculations restricts making this function as view.
    /// @return fetchPrice uint256 Price of one data request in ETH
    function calculateFetchPrice() external returns (uint256 fetchPrice);

    // Event with oracleId metadata JSON string (for DIB.ONE derivative explorer)
    event MetadataSet(string metadata);
}

// File: contracts/oracles/onchainSubIds/OnchainSubIdsOracleId.sol

pragma solidity 0.5.16;


interface IOracleAggregator {
  function __callback(uint256 timestamp, uint256 data) external;
  function hasData(address oracleId, uint256 timestamp) external view returns(bool result);
}

interface IOracleSubId {
  function getResult() external view returns (uint256);
}

contract OnchainSubIdsOracleId is IOracleId {
  event Provided(uint256 indexed timestamp, uint256 result);

  // Resolvers
  // Mapping timestamp => oracleSubId
  mapping (uint256 => address) public resolvers;

  // Opium
  IOracleAggregator public oracleAggregator;

  // Governance
  address private _owner;
  uint256 public EMERGENCY_PERIOD;

  modifier onlyOwner() {
    require(_owner == msg.sender, "N.O"); // N.O = not an owner
    _;
  }

  constructor(IOracleAggregator _oracleAggregator, uint256 _emergencyPeriod) public {
    // Opium
    oracleAggregator = _oracleAggregator;

    // Governance
    _owner = msg.sender;
    EMERGENCY_PERIOD = _emergencyPeriod;
    /*
    {
      "author": "Opium.Team",
      "description": "On-chain Universal Oracle",
      "asset": "Universal",
      "type": "onchain",
      "source": "subIds",
      "logic": "none",
      "path": "getResult()"
    }
    */
    emit MetadataSet("{\"author\":\"Opium.Team\",\"description\":\"On-chain Universal Oracle\",\"asset\":\"Universal\",\"type\":\"onchain\",\"source\":\"subIds\",\"logic\":\"none\",\"path\":\"getResult()\"}");
  }

  /** OPIUM INTERFACE */
  function fetchData(uint256 _timestamp) external payable {
    _timestamp;
    revert("N.S"); // N.S = not supported
  }

  function recursivelyFetchData(uint256 _timestamp, uint256 _period, uint256 _times) external payable {
    _timestamp;
    _period;
    _times;
    revert("N.S"); // N.S = not supported
  }

  function calculateFetchPrice() external returns (uint256) {
    return 0;
  }
  
  /** RESOLVER */
  function _callback(uint256 _timestamp) public {
    require(
      !oracleAggregator.hasData(address(this), _timestamp) &&
      _timestamp < now,
      "N.A" // N.A = Only when no data and after timestamp allowed
    );

    uint256 result = IOracleSubId(resolvers[_timestamp]).getResult();
    oracleAggregator.__callback(_timestamp, result);

    emit Provided(_timestamp, result);
  }

  function registerResolver(uint256 _timestamp, address _resolver) public {
    require(resolvers[_timestamp] == address(0), "O.R"); // O.R = already registered
    resolvers[_timestamp] = _resolver;
  }

  /** GOVERNANCE */
  /** 
    Emergency callback allows to push data manually in case EMERGENCY_PERIOD elapsed and no data were provided
   */
  function emergencyCallback(uint256 _timestamp, uint256 _result) public onlyOwner {
    require(
      !oracleAggregator.hasData(address(this), _timestamp) &&
      _timestamp + EMERGENCY_PERIOD  < now,
      "N.E" // N.E = Only when no data and after emergency period allowed
    );

    oracleAggregator.__callback(_timestamp, _result);

    emit Provided(_timestamp, _result);
  }
}