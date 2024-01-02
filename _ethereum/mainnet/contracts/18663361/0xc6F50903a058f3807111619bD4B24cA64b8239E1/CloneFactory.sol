// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/// Core /////
import "./sTRSY.sol";

/// Utils /////
import "./Clones.sol";

///@title  CloneFactory
///@notice Factory to deploy sTRSY-asset token and proxies for governance via the gas efficient
///        cloning pattern
abstract contract CloneFactory {
  address public immutable TOKEN_IMPLEMENTATION;

  constructor() {
    TOKEN_IMPLEMENTATION = address(new sTRSY(address(this)));
  }

  ///@dev deploys a minimal clone which delegate calls everything to the sTRSY contract. Clone is
  /// initialized with name and symbol to get distinct sTRSY token for each asset
  function _createToken(string memory _name, string memory _symbol) internal returns (address) {
    address clone = Clones.clone(TOKEN_IMPLEMENTATION);
    sTRSY(clone).initialize(_name, _symbol);
    return clone;
  }

  ///@dev deploys a minimal clone which delegate calls everything to the governance module. The
  /// proxy router in the governance module forward to the implementation.
  function _createProxy() internal returns (address) {
    return Clones.clone(address(this));
  }
}
