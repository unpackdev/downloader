import "./Proxy.sol";

pragma solidity 0.8.9;

contract Limiter is Proxy {
  constructor(
    address _bridgeIn,
    address _bridgeOut,
    address _admin,
    address _implementation
  ) Proxy(_implementation) {
    require(
      _bridgeIn != address(0) && _bridgeOut != address(0) && _admin != address(0),
      'invalid input'
    );
    delegateTo(
      _implementation,
      abi.encodeWithSignature('initialize(address,address,address)', _bridgeIn, _bridgeOut, _admin)
    );
  }

  function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
    (bool success, bytes memory returnData) = callee.delegatecall(data);
    assembly {
      if eq(success, 0) {
        revert(add(returnData, 0x20), returndatasize())
      }
    }
    return returnData;
  }

  receive() external payable {}

  fallback() external payable {
    // delegate all other functions to current implementation
    (bool success, ) = _implementation.delegatecall(msg.data);
    assembly {
      let free_mem_ptr := mload(0x40)
      returndatacopy(free_mem_ptr, 0, returndatasize())
      switch success
      case 0 {
        revert(free_mem_ptr, returndatasize())
      }
      default {
        return(free_mem_ptr, returndatasize())
      }
    }
  }
}
