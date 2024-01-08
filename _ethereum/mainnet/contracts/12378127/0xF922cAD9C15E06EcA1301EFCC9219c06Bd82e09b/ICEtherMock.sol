// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20Mock.sol";

// Export ICEther interface for mainnet-fork testing.
interface ICEtherMock is IERC20Mock {
  function mint() external payable;
}
