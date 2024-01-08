// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./IERC20Upgradeable.sol";

interface ITrancheToken is IERC20Upgradeable {
  function mint(address _account, uint256 _amount) external;

  function burn(address _account, uint256 _amount) external;

  function destroy(address payable _receiver) external;
}
