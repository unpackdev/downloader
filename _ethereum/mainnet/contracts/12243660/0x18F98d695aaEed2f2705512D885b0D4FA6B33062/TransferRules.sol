// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./ManualApproval.sol";
import "./Whitelisted.sol";
import "./SRC20.sol";
import "./ITransferRules.sol";

/*
 * @title TransferRules contract
 * @dev Contract that is checking if on-chain rules for token transfers are concluded.
 * It implements whitelist and grey list.
 */
contract TransferRules is ITransferRules, ManualApproval, Whitelisted {
  modifier onlySRC20 {
    require(msg.sender == address(src20), 'TransferRules: Caller not SRC20');
    _;
  }

  constructor(address _src20, address _owner) {
    src20 = SRC20(_src20);
    transferOwnership(_owner);
    whitelisted[_owner] = true;
  }

  /**
   * @dev Set for what contract this rules are.
   *
   * @param _src20 - Address of SRC20 contract.
   */
  function setSRC(address _src20) external override returns (bool) {
    require(address(src20) == address(0), 'SRC20 already set');
    src20 = SRC20(_src20);
    return true;
  }

  /**
   * @dev Checks if transfer passes transfer rules.
   *
   * @param sender The address to transfer from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   */
  function authorize(
    address sender,
    address recipient,
    uint256 amount
  ) public view returns (bool) {
    uint256 v;
    v = amount; // eliminate compiler warning
    return
      (isWhitelisted(sender) || isGreylisted(sender)) &&
      (isWhitelisted(recipient) || isGreylisted(recipient));
  }

  /**
   * @dev Do transfer and checks where funds should go. If both from and to are
   * on the whitelist funds should be transferred but if one of them are on the
   * grey list token-issuer/owner need to approve transfer.
   *
   * @param sender The address to transfer from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   */
  function doTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external override onlySRC20 returns (bool) {
    require(authorize(sender, recipient, amount), 'Transfer not authorized');

    if (isGreylisted(sender) || isGreylisted(recipient)) {
      _requestTransfer(sender, recipient, amount);
      return true;
    }

    require(SRC20(src20).executeTransfer(sender, recipient, amount), 'SRC20 transfer failed');

    return true;
  }
}
