// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract EktaSwap is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  IERC20Upgradeable public swapToken;

  event Swapped(address account, uint256 amount);
  event TokenFromContractTransferred(address externalAddress,address toAddress, uint amount);
  event TokenSwapUpdated(address token);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address _swapToken) public initializer {
    // initializing
    __Ownable_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    swapToken = IERC20Upgradeable(_swapToken);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function swap(uint256 amount) external nonReentrant whenNotPaused {
    require(amount > 0, "Amount cant be zero");
    swapToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Swapped(msg.sender, amount);
  }

  function pauseContract() external virtual onlyOwner {
    _pause();
  }

  function unPauseContract() external virtual onlyOwner {
    _unpause();
  }

  function updateSwapToken(address token) external virtual onlyOwner nonReentrant whenNotPaused {
    require(token != address(0), "Token cant be zero address");
    swapToken = IERC20Upgradeable(token);
    emit TokenSwapUpdated(token);
  }

  function withdrawERC20Token(address _tokenContract, uint256 amount) external onlyOwner {
    require(_tokenContract != address(0), "Bridge: Address cant be zero address");
    IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
    require(amount <= tokenContract.balanceOf(address(this)), "Bridge: Amount exceeds balance");
		tokenContract.transfer(msg.sender, amount);
    emit TokenFromContractTransferred(_tokenContract, msg.sender, amount);
	}
}
