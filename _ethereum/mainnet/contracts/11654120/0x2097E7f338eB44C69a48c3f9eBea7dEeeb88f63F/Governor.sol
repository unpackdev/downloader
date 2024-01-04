// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MultiRole.sol";
import "./FixedPoint.sol";
import "./Testable.sol";
import "./FinderInterface.sol";
import "./IdentifierWhitelistInterface.sol";
import "./OracleInterface.sol";
import "./Constants.sol";

import "./SafeMath.sol";
import "./Address.sol";

contract Governor is MultiRole, Testable {
  using SafeMath for uint256;
  using Address for address;

  enum Roles {Owner, Proposer}

  struct Transaction {
    address to;
    uint256 value;
    bytes data;
  }

  struct Proposal {
    Transaction[] transactions;
    uint256 requestTime;
  }

  FinderInterface private finder;
  Proposal[] public proposals;

  event NewProposal(uint256 indexed id, Transaction[] transactions);

  event ProposalExecuted(uint256 indexed id, uint256 transactionIndex);

  constructor(
    address _finderAddress,
    uint256 _startingId,
    address _timerAddress
  ) public Testable(_timerAddress) {
    finder = FinderInterface(_finderAddress);
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );
    _createExclusiveRole(
      uint256(Roles.Proposer),
      uint256(Roles.Owner),
      msg.sender
    );

    uint256 maxStartingId = 10**18;
    require(
      _startingId <= maxStartingId,
      'Cannot set startingId larger than 10^18'
    );

    assembly {
      sstore(proposals_slot, _startingId)
    }
  }

  function propose(Transaction[] memory transactions)
    public
    onlyRoleHolder(uint256(Roles.Proposer))
  {
    uint256 id = proposals.length;
    uint256 time = getCurrentTime();

    proposals.push();

    Proposal storage proposal = proposals[id];
    proposal.requestTime = time;

    for (uint256 i = 0; i < transactions.length; i++) {
      require(
        transactions[i].to != address(0),
        'The `to` address cannot be 0x0'
      );

      if (transactions[i].data.length > 0) {
        require(
          transactions[i].to.isContract(),
          "EOA can't accept tx with data"
        );
      }
      proposal.transactions.push(transactions[i]);
    }

    bytes32 identifier = _constructIdentifier(id);

    OracleInterface oracle = _getOracle();
    IdentifierWhitelistInterface supportedIdentifiers =
      _getIdentifierWhitelist();
    supportedIdentifiers.addSupportedIdentifier(identifier);

    oracle.requestPrice(identifier, time);
    supportedIdentifiers.removeSupportedIdentifier(identifier);

    emit NewProposal(id, transactions);
  }

  function executeProposal(uint256 id, uint256 transactionIndex)
    external
    payable
  {
    Proposal storage proposal = proposals[id];
    int256 price =
      _getOracle().getPrice(_constructIdentifier(id), proposal.requestTime);

    Transaction memory transaction = proposal.transactions[transactionIndex];

    require(
      transactionIndex == 0 ||
        proposal.transactions[transactionIndex.sub(1)].to == address(0),
      'Previous tx not yet executed'
    );
    require(transaction.to != address(0), 'Tx already executed');
    require(price != 0, 'Proposal was rejected');
    require(msg.value == transaction.value, 'Must send exact amount of ETH');

    delete proposal.transactions[transactionIndex];

    require(
      _executeCall(transaction.to, transaction.value, transaction.data),
      'Tx execution failed'
    );

    emit ProposalExecuted(id, transactionIndex);
  }

  function numProposals() external view returns (uint256) {
    return proposals.length;
  }

  function getProposal(uint256 id) external view returns (Proposal memory) {
    return proposals[id];
  }

  function _executeCall(
    address to,
    uint256 value,
    bytes memory data
  ) private returns (bool) {
    bool success;
    assembly {
      let inputData := add(data, 0x20)
      let inputDataSize := mload(data)
      success := call(gas(), to, value, inputData, inputDataSize, 0, 0)
    }
    return success;
  }

  function _getOracle() private view returns (OracleInterface) {
    return
      OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
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

  function _constructIdentifier(uint256 id) internal pure returns (bytes32) {
    bytes32 bytesId = _uintToUtf8(id);
    return _addPrefix(bytesId, 'Admin ', 6);
  }

  function _uintToUtf8(uint256 v) internal pure returns (bytes32) {
    bytes32 ret;
    if (v == 0) {
      ret = '0';
    } else {
      uint256 bitsPerByte = 8;
      uint256 base = 10;
      uint256 utf8NumberOffset = 48;
      while (v > 0) {
        ret = ret >> bitsPerByte;

        uint256 leastSignificantDigit = v % base;

        bytes32 utf8Digit = bytes32(leastSignificantDigit + utf8NumberOffset);

        ret |= utf8Digit << (31 * bitsPerByte);

        v /= base;
      }
    }
    return ret;
  }

  function _addPrefix(
    bytes32 input,
    bytes32 prefix,
    uint256 prefixLength
  ) internal pure returns (bytes32) {
    bytes32 shiftedInput = input >> (prefixLength * 8);
    return shiftedInput | prefix;
  }
}
