// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.12;

import "./ERC20.sol";

library Console {
  bool constant PROD = false;

  function concat(string memory a, string memory b) internal pure returns(string memory)
  {
    return string(abi.encodePacked(a, b));
  }

  function concat(string memory a, string memory b, string memory c) internal pure returns(string memory)
  {
    return string(abi.encodePacked(a, b, c));
  }

  event LogBalance(string, uint);
  function logBalance(address token, address to) internal {
    if (PROD) return;
    emit LogBalance(ERC20(token).symbol(), ERC20(token).balanceOf(to));
  }

  function logBalance(string memory s, address token, address to) internal {
    if (PROD) return;
    emit LogBalance(string(abi.encodePacked(s, '/', ERC20(token).symbol())), ERC20(token).balanceOf(to));
  }

  event LogUint(string, uint);
  function log(string memory s, uint x) internal {
    if (PROD) return;
    emit LogUint(s, x);
  }

  function log(string memory s, string memory t, uint x) internal {
    if (PROD) return;
    emit LogUint(concat(s, t), x);
  }
    
  function log(string memory s, string memory t, string memory u, uint x) internal {
    if (PROD) return;
    emit LogUint(concat(s, t, u), x);
  }
    
  event LogInt(string, int);
  function log(string memory s, int x) internal {
    if (PROD) return;
    emit LogInt(s, x);
  }
  
  event LogBytes(string, bytes);
  function log(string memory s, bytes memory x) internal {
    if (PROD) return;
    emit LogBytes(s, x);
  }
  
  event LogBytes32(string, bytes32);
  function log(string memory s, bytes32 x) internal {
    if (PROD) return;
    emit LogBytes32(s, x);
  }

  event LogAddress(string, address);
  function log(string memory s, address x) internal {
    if (PROD) return;
    emit LogAddress(s, x);
  }

  event LogBool(string, bool);
  function log(string memory s, bool x) internal {
    if (PROD) return;
    emit LogBool(s, x);
  }
}
