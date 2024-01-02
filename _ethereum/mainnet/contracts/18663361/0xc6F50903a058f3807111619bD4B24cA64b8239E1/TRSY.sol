// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./ERC20.sol";

///@title TRSY contract
///@notice Handle the logic for minting and burning TRSY shares
abstract contract TRSY is ERC20 {
  /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor() ERC20("TRSY", "TRSY", 18) {}

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  ///@notice Convert the value of deposit into share of the protocol
  ///@param _usdValue usd value of the deposit
  ///@param _usdAUM AUM of the protocol in USD (given by keeper)
  ///@return TSRY share for an USD deposit
  function _convertToShares(uint256 _usdValue, uint256 _usdAUM) internal view returns (uint256) {
    uint256 supply = totalSupply;
    return supply == 0 ? _usdValue : (_usdValue * supply) / _usdAUM;
  }
}
