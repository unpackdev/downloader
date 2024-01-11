// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract DogeToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address tokenAdmin) external initializer {
    // Contract initialization
    // TODO: decide token name and symbol
    __ERC20_init("DogeToken", "DOGE");
    __Ownable_init();

    // Must happen after initialization.
    _transferOwnership(tokenAdmin);
  }

  function mint(uint256 amount) public onlyOwner {
    _mint(owner(), amount);
  }

  function burn(uint256 amount) public onlyOwner {
    _burn(owner(), amount);
  }

  /**
   * @dev Returns the number of decimals used to get its human representation.
   * Dogecoin has 8 decimals so that's what we use here too.
   */
  function decimals() public pure virtual override returns (uint8) {
    return 8;
  }

  function getVersion() external pure returns (uint256) {
    return 1;
  }
}
