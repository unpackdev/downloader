// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

/// @title Interface to retrieve the number of minted NFTs
/// @author Martin Wawrusch
/// @notice This interface is used to retrieve the number of minted NFTs
interface INumberMinted {
  function numberMinted(address adr) external view returns (uint256);
}
