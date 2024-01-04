pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


interface SimulatorInterface {
  // ABIEncoderV2 uses an array of Calls for executing generic batch calls.
  struct Call {
    address to;
    uint96 value;
    bytes data;
  }

  struct ValueReplacement {
      uint16 callIndex;
      uint24 returnDataOffset;
      bool perform;
  }

  struct DataReplacement {
      uint16 callIndex;
      uint24 returnDataOffset;
      uint24 callDataOffset;
  }

  struct AdvancedCall {
    address to;
    uint96 value;
    bytes data;
    ValueReplacement replaceValue;
    DataReplacement[] replaceData;
  }

  // ABIEncoderV2 uses an array of CallReturns for handling generic batch calls.
  struct CallReturn {
    bool ok;
    bytes returnData;
  }

  struct AdvancedCallReturn {
    bool ok;
    bytes returnData;
    uint96 callValue;
    bytes callData;
  }

  function simulateActionWithAtomicBatchCalls(
    Call[] calldata calls
  ) external /* view */ returns (bool[] memory ok, bytes[] memory returnData);

  function simulateAdvancedActionWithAtomicBatchCalls(
    AdvancedCall[] calldata calls
  ) external /* view */ returns (bool[] memory ok, bytes[] memory returnData);
}


library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}


contract Simulator is SimulatorInterface {
  using Address for address;

  bytes4 private _selfCallContext;

  address private _owner;

  constructor() public {
    _owner = tx.origin;
  }

  function updateOwner(address owner) external {
    require(msg.sender == _owner, "Only owner may call this function.");
    _owner = owner;
  }

  function callAny(
    Call memory targetCall
  ) public returns (bool ok, bytes memory returnData) {
      require(msg.sender == _owner, "Only owner may call this function.");
      (ok, returnData) = targetCall.to.call.value(
        uint256(targetCall.value)
      )(targetCall.data);
  }

  function simulateActionWithAtomicBatchCalls(
    Call[] memory calls
  ) public /* view */ returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _simulateActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.simulateActionWithAtomicBatchCalls.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool mustBeFalse, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulateActionWithAtomicBatchCallsAtomic.selector, calls
      )
    );

    // Note: this should never be the case, but check just to be extra safe.
    if (mustBeFalse) {
      revert("Simulation code must revert!");
    }

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      if (!callResults[i].ok) {
        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  function _simulateActionWithAtomicBatchCallsAtomic(
    Call[] memory calls
  ) public returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.simulateActionWithAtomicBatchCalls.selector);

    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call.value(
        uint256(calls[i].value)
      )(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }
    }

    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  function simulateAdvancedActionWithAtomicBatchCalls(
    AdvancedCall[] memory calls
  ) public /* view */ returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _simulateActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.simulateAdvancedActionWithAtomicBatchCalls.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool mustBeFalse, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulateAdvancedActionWithAtomicBatchCallsAtomic.selector, calls
      )
    );

    // Note: this should never be the case, but check just to be extra safe.
    if (mustBeFalse) {
      revert("Simulation code must revert!");
    }

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      if (!callResults[i].ok) {
        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  function _simulateAdvancedActionWithAtomicBatchCallsAtomic(
    AdvancedCall[] memory calls
  ) public returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.simulateAdvancedActionWithAtomicBatchCalls.selector);

    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      AdvancedCall memory a = calls[i];
      uint256 callValue = uint256(a.value);
      bytes memory callData = a.data;

      // Note: this check could (should?) be performed prior to execution.
      if (a.replaceValue.perform) {
        if (i <= a.replaceValue.callIndex) {
          revert("Cannot replace value using call that has not yet been performed.");
        }

        uint256 returnOffset = a.replaceValue.returnDataOffset;
        bytes memory resultsAtIndex = callResults[a.replaceValue.callIndex].returnData;

        if (resultsAtIndex.length < returnOffset + 32) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        // TODO: this can be made much more efficient via assembly
        bytes memory valueData = new bytes(32);
        for (uint256 k = 0; k < 32; k++) {
            valueData[k] = resultsAtIndex[returnOffset + k];
        }
        callValue = abi.decode(valueData, (uint256));
      }

      for (uint256 j = 0; j < a.replaceData.length; j++) {
        if (i <= a.replaceData[j].callIndex) {
          revert("Cannot replace data using call that has not yet been performed.");
        }

        uint256 callOffset = a.replaceData[j].callDataOffset;
        uint256 returnOffset = a.replaceData[j].returnDataOffset;
        bytes memory resultsAtIndex = callResults[a.replaceData[j].callIndex].returnData;

        if (resultsAtIndex.length < returnOffset + 32) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        for (uint256 k = 0; k < 32; k++) {
            callData[callOffset + k] = resultsAtIndex[returnOffset + k];
        }
      }

      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = a.to.call.value(callValue)(callData);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }
    }

    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  function _enforceSelfCallFrom(bytes4 selfCallContext) internal {
    // Ensure caller is this contract and self-call context is correctly set.
    if (msg.sender != address(this) || _selfCallContext != selfCallContext) {
      revert("External accounts or unapproved internal functions cannot call this.");
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  function _ensureValidGenericCallTarget(address to) internal view {
    if (!to.isContract()) {
      revert("Cannot call accounts with no code with no value.");
    }

    if (to == address(this)) {
      revert("Cannot call this contract.");
    }
  }
}