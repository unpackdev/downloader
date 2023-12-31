// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

interface IPGAT {

  function setMinerContract(address _minerContract) external;

  function pause() external;

  function unpause() external;

  function mint(address to, uint256 amount) external;
}
