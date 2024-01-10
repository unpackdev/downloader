pragma solidity 0.5.8;

contract ReturnData {
  function _returnReturnData(bool _success) internal pure {
    assembly {
      let returndatastart := 0
      returndatacopy(returndatastart, 0, returndatasize)
      switch _success
      case 0 {
        revert(returndatastart, returndatasize)
      }
      default {
        return(returndatastart, returndatasize)
      }
    }
  }

  function _assemblyCall(
    address _destination,
    uint256 _value,
    bytes memory _data
  ) internal returns (bool success) {
    assembly {
      success := call(gas, _destination, _value, add(_data, 32), mload(_data), 0, 0)
    }
  }
}
