// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";

/**
 * @title ShareSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `ShareSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract ShareSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PayeeReplaced(address from, address to);
    event PaymentReleased(address sender, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `ShareSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor (address[] memory payees, uint256[] memory shares_) payable {
        // solhint-disable-next-line max-line-length
        require(payees.length == shares_.length, "ShareSplitter: payees and shares length mismatch");
        require(payees.length > 0, "ShareSplitter: no payees");

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
    receive () external payable virtual {
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
     * @dev Setter for the address of the payee number `index`.
     */
    function replacePayee(uint256 index, address newPayee) public {
        require(_payees[index] == _msgSender(), "You do not have permission for this payee");
        require(_shares[_msgSender()] > 0, "ShareSplitter: account has no shares");
        require(newPayee != address(0), "ShareSplitter: newPayee is the zero address");
        require(_shares[newPayee] == 0, "ShareSplitter: newPayee already has shares");
        
        _shares[newPayee] = _shares[_msgSender()];
        _released[newPayee] = _released[_msgSender()];
        _shares[_msgSender()] = 0;
        _released[_msgSender()] = 0;
        _payees[index] = newPayee;
        emit PayeeReplaced(_msgSender(), newPayee);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[_msgSender()] > 0, "ShareSplitter: sender has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = totalReceived * _shares[_msgSender()] / _totalShares - _released[_msgSender()];

        require(payment != 0, "ShareSplitter: sender is not due payment");

        _released[_msgSender()] = _released[_msgSender()] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(_msgSender(), account, payment);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "ShareSplitter: account is the zero address");
        require(shares_ > 0, "ShareSplitter: shares are 0");
        require(_shares[account] == 0, "ShareSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}
