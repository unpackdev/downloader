
// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./ERC20.sol";
import "./Ownable.sol";

contract TAlphaToken is ERC20("TAlphaToken", "TALPHA"), Ownable {
  /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
  function mint(address _to, uint256 _amount) public onlyOwner {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public onlyOwner {
    _burn(_from, _amount);
  }
}