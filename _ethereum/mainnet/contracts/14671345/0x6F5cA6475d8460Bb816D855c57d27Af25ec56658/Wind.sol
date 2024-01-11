// contracts/Cruise.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";


contract Wind is ERC20, Ownable {
  /**
  * @dev Set the maximum issuance cap and token details.
  */
  constructor ()
  ERC20("WIND TOKEN", "WIND")
  // ERC20Capped( 50 * (10**9) * (10**18) )
  {
      _mint(msg.sender, 5 * (10**8) * (10**18));
  }
}