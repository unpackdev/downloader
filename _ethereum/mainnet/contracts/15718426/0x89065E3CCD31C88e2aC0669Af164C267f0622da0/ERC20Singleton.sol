// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IERC20Singleton.sol";

contract ERC20Singleton is
  IERC20Singleton,
  Initializable,
  ERC20Upgradeable,
  OwnableUpgradeable
{
  error MaxSupplyReached();

  uint256 maxSupply;

  constructor() initializer {
    __ERC20_init("Singleton Base", "BASE");
    __Ownable_init();
    maxSupply = 1 ether;
    transferOwnership(address(1));
  }

  function initialize(
    bytes calldata _name,
    bytes calldata _symbol,
    uint256 _maxSupply,
    address _owner
  ) external initializer {
    __ERC20_init(string(_name), string(_symbol));
    __Ownable_init();
    maxSupply = _maxSupply;
    transferOwnership(_owner);
  }

  function mint(address account, uint256 amount) external override onlyOwner {
    if (this.totalSupply() + amount > maxSupply) {
      revert MaxSupplyReached();
    }
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external override onlyOwner {
    _burn(account, amount);
  }
}
