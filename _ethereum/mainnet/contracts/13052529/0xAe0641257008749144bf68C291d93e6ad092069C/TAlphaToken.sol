
// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./ERC20.sol";
import "./Ownable.sol";
import "./console.sol";

contract TAlphaToken is ERC20("TAlphaToken", "TALPHA"), Ownable {
  address private _minter;

  function minter() public view returns (address) {
    return _minter;
  }

  modifier onlyOwnerOrMinter() {
    require(owner() == _msgSender() || minter() == _msgSender(), "caller is not the owner or minter");
    _;
  }

  /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
  function mint(address _to, uint256 _amount) public onlyOwnerOrMinter {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public onlyOwnerOrMinter {
    _burn(_from, _amount);
  }

  function setMinter(address __minter) public onlyOwner {
    _minter = __minter;
  }
}