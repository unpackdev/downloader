// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./Ownable2Step.sol";
import "./IUSDeDefinitions.sol";

/**
 * @title USDe
 * @notice USDe Genesis Story: Arthur Hayes' $Nakadollar in "Dust on Crust" 08/03/2023
 */
contract USDe is Ownable2Step, ERC20Burnable, ERC20Permit, IUSDeDefinitions {
  address public minter;

  constructor(address admin) ERC20("USDe", "USDe") ERC20Permit("USDe") {
    if (admin == address(0)) revert ZeroAddressException();
    _transferOwnership(admin);
  }

  function setMinter(address newMinter) external onlyOwner {
    emit MinterUpdated(newMinter, minter);
    minter = newMinter;
  }

  function mint(address to, uint256 amount) external {
    if (msg.sender != minter) revert OnlyMinter();
    _mint(to, amount);
  }

  function renounceOwnership() public view override onlyOwner {
    revert CantRenounceOwnership();
  }
}
