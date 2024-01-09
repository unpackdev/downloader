// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";

contract SmartSplit is Initializable, ContextUpgradeable {
  using SafeMathUpgradeable for uint256;

  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);
  event PayeeUpdated(address from, address to);

  uint256 private _totalShares;
  uint256 private _totalReleased;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;

  /**
   * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
   * the matching position in the `shares` array.
   *
   * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
   * duplicates in `payees`.
   */
  function init(address[] memory payees, uint256[] memory shares_)
    public
    initializer
  {
    require(
      payees.length == shares_.length,
      "PaymentSplitter: payees and shares length mismatch"
    );
    require(payees.length > 0, "PaymentSplitter: no payees");

    for (uint256 i = 0; i < payees.length; i++) {
      _addPayee(payees[i], shares_[i]);
    }
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  /**
   * @dev Getter for the total shares held by payees.
   */
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  function changePayee(address newAddress) public virtual {
    require(
      newAddress != address(0),
      "changePayee::cant update to zero address"
    );

    uint256 senderShares = _shares[_msgSender()];
    uint256 senderReleased = _released[_msgSender()];

    require(senderShares != 0, "changePayee::sender has 0 shares");

    _shares[_msgSender()] = 0;
    _shares[newAddress] = senderShares;

    _released[_msgSender()] = 0;
    _released[newAddress] = senderReleased;

    emit PayeeUpdated(_msgSender(), newAddress);
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function release(address payable account) public virtual {
    require(_shares[account] > 0, "PaymentSplitter: account has no shares");

    uint256 totalReceived = address(this).balance.add(_totalReleased);
    uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(
      _released[account]
    );

    require(payment != 0, "PaymentSplitter: account is not due payment");

    _released[account] = _released[account].add(payment);
    _totalReleased = _totalReleased.add(payment);

    AddressUpgradeable.sendValue(account, payment);
    emit PaymentReleased(account, payment);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  function _addPayee(address account, uint256 shares_) private {
    require(
      account != address(0),
      "PaymentSplitter: account is the zero address"
    );
    require(shares_ > 0, "PaymentSplitter: shares are 0");
    require(
      _shares[account] == 0,
      "PaymentSplitter: account already has shares"
    );

    _shares[account] = shares_;
    _totalShares = _totalShares.add(shares_);
    emit PayeeAdded(account, shares_);
  }

  uint256[45] private __gap;
}
