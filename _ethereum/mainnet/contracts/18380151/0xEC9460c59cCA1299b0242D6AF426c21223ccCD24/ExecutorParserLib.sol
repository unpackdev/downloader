// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ExecutorParserLib
 * @notice Library to parse additional data from Executor messages.
 */
library ExecutorParserLib {

  /// @notice Parses the message ID from `msg.data`.
  /// @return The bytes32 message ID uniquely identifying the message that was executed
  function messageId() internal pure returns (bytes32) {
    bytes32 _messageId;
    if (msg.data.length >= 84) {
      assembly {
        _messageId := calldataload(sub(calldatasize(), 84))
      }
    }
    return _messageId;
  }

  /// @notice Parses the from chain ID from `msg.data`.
  /// @return ID of the chain that dispatched the messages
  function fromChainId() internal pure returns (uint256) {
    uint256 _fromChainId;
    if (msg.data.length >= 52) {
      assembly {
        _fromChainId := calldataload(sub(calldatasize(), 52))
      }
    }
    return _fromChainId;
  }

  /// @notice Parses the sender address from `msg.data`.
  /// @return The payable sender address
  function msgSender() internal pure returns (address payable) {
    address payable _sender;
    if (msg.data.length >= 20) {
      assembly {
        _sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
    return _sender;
  }

}