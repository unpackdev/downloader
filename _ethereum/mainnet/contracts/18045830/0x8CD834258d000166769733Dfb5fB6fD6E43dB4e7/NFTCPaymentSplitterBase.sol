// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Address.sol";
import "./Context.sol";

/**
 * @title NFTCPaymentSplitterBase
 * @author @NiftyMike | @NFTCulture
 * @dev An opinionated replacement of OZ's Payment Splitter.
 *
 * Notes:
 *  - Based on OZ Contracts v4.8.0 (finance/PaymentSplitter.sol)
 *  - ERC-20 token functionality removed to save gas.
 *  - Transferability of Payees, but only by Payee
 *  - Some require messages are shortened.
 *  - contract changed to abstract and release() functionality moved to internal method.
 *
 * IMPORTANT: changes to release() require higher level classes to expose release() in order
 * for funds to be withdrawn. This allows higher level classes to enforce better controls.
 */
abstract contract NFTCPaymentSplitterBase is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event PayeeTransferred(address oldOwner, address newOwner);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, 'PaymentSplitter: length mismatch');
        require(payees.length > 0, 'PaymentSplitter: no payees');

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

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        return _releasable(account);
    }

    function _releasable(address account) internal view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _release(address payable account) internal {
        require(_shares[account] > 0, 'PaymentSplitter: no shares');

        uint256 payment = _releasable(account);

        require(payment != 0, 'PaymentSplitter: not due payment');

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[account] += payment;
        }

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), 'PaymentSplitter: zero address');
        require(shares_ > 0, 'PaymentSplitter: no shares');
        require(_shares[account] == 0, 'PaymentSplitter: payee has shares');

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Allows owner to transfer their shares to somebody else; it can only be called by of a share.
     * @notice Owner: Release funds to a specific address.
     *
     * @param newOwner Payable address which has no shares and will receive the shares of the current owner.
     */
    function transferPayee(address payable newOwner) public {
        require(newOwner != address(0), 'PaymentSplitter: zero address');
        require(_shares[_msgSender()] > 0, 'PaymentSplitter: no owned shares');
        require(_shares[newOwner] == 0, 'PaymentSplitter: payee has shares');

        _transferPayee(newOwner);
        emit PayeeTransferred(_msgSender(), newOwner);
    }

    function _transferPayee(address newOwner) private {
        if (_payees.length == 0) return;

        for (uint i = 0; i < _payees.length - 1; i++) {
            if (_payees[i] == _msgSender()) {
                _payees[i] = newOwner;
                _shares[newOwner] = _shares[_msgSender()];
                _shares[_msgSender()] = 0;
            }
        }
    }

    function release(address payable account) public virtual;
}
