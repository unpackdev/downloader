// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

import "./BaseRelayRecipient.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IIdleTokenV3_1.sol";
import "./IERC20Permit.sol";

contract IdleDepositForwarder is BaseRelayRecipient, Initializable, OwnableUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  string public override versionRecipient;

  address public idleToken;
  address public underlying;

  function initialize(address _trustedForwarder, address _idleToken) public initializer {
    versionRecipient = "2.0.0-alpha.1+opengsn.test.recipient";
    trustedForwarder = _trustedForwarder;
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
    idleToken = _idleToken;
    underlying = IIdleTokenV3_1(idleToken).token();
    IERC20Upgradeable(underlying).safeApprove(idleToken, uint256(-1));
  }

  function setBiconomyConfig(string memory _versionRecipient, address _trustedForwarder) public onlyOwner {
    versionRecipient = _versionRecipient;
    trustedForwarder = _trustedForwarder;
  }

  function permitAndDeposit(uint256 amount, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
    // the original sender, sent by the trusted forwarder
    address sender = _forwardedMsgSender();
    IERC20Permit(underlying).permit(sender, address(this), nonce, expiry, true, v, r, s);
    deposit(sender, amount);
  }

  function permitEIP2612AndDeposit(uint256 amount, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
    // the original sender, sent by the trusted forwarder
    address sender = _forwardedMsgSender();
    IERC20Permit(underlying).permit(sender, address(this), amount, expiry, v, r, s);
    deposit(sender, amount);
  }

  function deposit(address sender, uint256 amount) internal {
    IERC20Upgradeable(underlying).safeTransferFrom(sender, address(this), amount);
    uint256 minted = IIdleTokenV3_1(idleToken).mintIdleToken(amount, true, address(0));
    IERC20Upgradeable(idleToken).safeTransfer(sender, minted);
  }

  function emergencyWithdrawToken(address _token, address _to) external onlyOwner {
    IERC20Upgradeable(_token).safeTransfer(_to, IERC20Upgradeable(_token).balanceOf(address(this)));
  }

  function pause() external onlyOwner {
    _pause();
  }
}
