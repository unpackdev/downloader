
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
//import "./IERC20Metadata.sol";

/// Local imports


interface VaultInterface /*is IERC20Metadata */ {

  //function deposit() external returns (uint256);

  function deposit(uint256 amount) external returns (uint256);

  //function deposit(uint256 amount, address recipient) external returns (uint256);

  //function withdraw() external returns (uint256);

  //function withdraw(uint256 maxShares) external returns (uint256);

  function withdraw(uint256 maxShares, address recipient) external returns (uint256);

  //function withdraw(uint256 maxShares, address recipient, uint256 maxLoss) external returns (uint256);

  function balanceOf(address user) view external returns(uint256);

  function pricePerShare() external view returns (uint256);
}
