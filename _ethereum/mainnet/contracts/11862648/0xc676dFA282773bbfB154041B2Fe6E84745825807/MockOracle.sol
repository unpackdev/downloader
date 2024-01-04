// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./Testable.sol";
import "./OracleInterface.sol";
import "./IdentifierWhitelistInterface.sol";
import "./FinderInterface.sol";
import "./Constants.sol";

contract MockOracle is OracleInterface, Testable {
  struct Price {
    bool isAvailable;
    int256 price;
    uint256 verifiedTime;
  }

  struct QueryIndex {
    bool isValid;
    uint256 index;
  }

  struct QueryPoint {
    bytes32 identifier;
    uint256 time;
  }

  FinderInterface private finder;

  mapping(bytes32 => mapping(uint256 => Price)) private verifiedPrices;

  mapping(bytes32 => mapping(uint256 => QueryIndex)) private queryIndices;
  QueryPoint[] private requestedPrices;

  constructor(address _finderAddress, address _timerAddress)
    public
    Testable(_timerAddress)
  {
    finder = FinderInterface(_finderAddress);
  }

  function requestPrice(bytes32 identifier, uint256 time) public override {
    require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
    Price storage lookup = verifiedPrices[identifier][time];
    if (!lookup.isAvailable && !queryIndices[identifier][time].isValid) {
      queryIndices[identifier][time] = QueryIndex(true, requestedPrices.length);
      requestedPrices.push(QueryPoint(identifier, time));
    }
  }

  function pushPrice(
    bytes32 identifier,
    uint256 time,
    int256 price
  ) external {
    verifiedPrices[identifier][time] = Price(true, price, getCurrentTime());

    QueryIndex storage queryIndex = queryIndices[identifier][time];
    require(
      queryIndex.isValid,
      "Can't push prices that haven't been requested"
    );

    uint256 indexToReplace = queryIndex.index;
    delete queryIndices[identifier][time];
    uint256 lastIndex = requestedPrices.length - 1;
    if (lastIndex != indexToReplace) {
      QueryPoint storage queryToCopy = requestedPrices[lastIndex];
      queryIndices[queryToCopy.identifier][queryToCopy.time]
        .index = indexToReplace;
      requestedPrices[indexToReplace] = queryToCopy;
    }
  }

  function hasPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (bool)
  {
    require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
    Price storage lookup = verifiedPrices[identifier][time];
    return lookup.isAvailable;
  }

  function getPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (int256)
  {
    require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
    Price storage lookup = verifiedPrices[identifier][time];
    require(lookup.isAvailable);
    return lookup.price;
  }

  function getPendingQueries() external view returns (QueryPoint[] memory) {
    return requestedPrices;
  }

  function _getIdentifierWhitelist()
    private
    view
    returns (IdentifierWhitelistInterface supportedIdentifiers)
  {
    return
      IdentifierWhitelistInterface(
        finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
      );
  }
}
