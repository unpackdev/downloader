pragma solidity ^0.8.11;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Errors.sol";
import "./IveSDT.sol";

contract SDTController is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
  address public constant veSDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;

  constructor() initializer {}

  function initialize() external initializer {
    __Ownable_init();
  }

  function createLock(uint256 value, uint256 lockTime) external onlyOwner {
    IveSDT(veSDT).create_lock(value, lockTime);
  }

  function sweep(address token, uint256 amount) external onlyOwner {
    IERC20Upgradeable(token).safeTransfer(owner(), amount);
  }
}
