pragma solidity ^0.8.11;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Errors.sol";
import "./IveSDT.sol";
import "./IRewardDistributor.sol";
import "./IDelegateRegistry.sol";
import "./ILiquidityGauge.sol";

contract SDTController is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
  address public constant veSDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
  string public constant version = "1.1.0";

  address public delegateRegistry;
  address public rewardDistributor;
  address public rewardToken;
  address public crvRewardDistributor;

  constructor() initializer {}

  function initialize() external initializer {
    __Ownable_init();
    delegateRegistry = 0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446;
    rewardDistributor = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
    rewardToken = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
  }

  function createLock(uint256 value, uint256 lockTime) external onlyOwner {
    IERC20Upgradeable(SDT).approve(veSDT, value);
    IveSDT(veSDT).create_lock(value, lockTime);
  }

  function increaseLockAmount(uint256 value) external onlyOwner {
    IERC20Upgradeable(SDT).approve(veSDT, value);
    IveSDT(veSDT).increase_amount(value);
  }

  function increaseLockTime(uint256 lockTime) external onlyOwner {
    IveSDT(veSDT).increase_unlock_time(lockTime);
  }

  function sweep(address token, uint256 amount) external onlyOwner {
    IERC20Upgradeable(token).safeTransfer(owner(), amount);
  }

  function setDelegateRegistry(address _delegateRegistry) external onlyOwner {
    delegateRegistry = _delegateRegistry;
  }

  function setDelegate(bytes32 id, address delegate) external onlyOwner {
    IDelegateRegistry(delegateRegistry).setDelegate(id, delegate);
  }

  function clearDelegate(bytes32 id) external onlyOwner {
    IDelegateRegistry(delegateRegistry).clearDelegate(id);
  }

  function setRewardDistributor(address _rewardDistributor) external onlyOwner {
    rewardDistributor = _rewardDistributor;
  }

  function setRewardToken(address _rewardToken) external onlyOwner {
    rewardToken = _rewardToken;
  }

  function claim() external onlyOwner {
    uint256 amountClaimed = IRewardDistributor(rewardDistributor).claim();
    IERC20Upgradeable(rewardToken).safeTransfer(owner(), amountClaimed);
  }

  function setCrvRewardDistributor(address _crvRewardDistributor) external onlyOwner {
    crvRewardDistributor = _crvRewardDistributor;
  }

  function claimRewards() external onlyOwner {
    ILiquidityGauge(crvRewardDistributor).claim_rewards(address(this), owner());
  }
}
