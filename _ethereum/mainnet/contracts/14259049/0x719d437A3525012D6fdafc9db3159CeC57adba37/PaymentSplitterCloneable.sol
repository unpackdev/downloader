// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";

/**
 * @title PaymentSplitterCloneable
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * This is a cloneable version of the OpenZeppelin PaymentSplitter contract. It also includes the new method releaseAll
 * which is meant to improve the workflow for when sending payments to all the addresses.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitterCloneable is Context {
    bool _splitterInitialized;

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    modifier splitterInitialized() {
        require(_splitterInitialized, "PaymentSplitterCloneable: hasn't been initialized yet.");
        _;
    }

    /**
     * @dev Initializes an instance of `PaymentSplitterCloneable` where each account in
     *  `payees` is assigned the number of shares at the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function initializeSplitter(address[] memory payees, uint256[] memory shares_) public payable {
        require(!_splitterInitialized, "PaymentSplitterCloneable: already init.");
        require(payees.length == shares_.length, "PaymentSplitterCloneable: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitterCloneable: no payees");
        _splitterInitialized = true;

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
    function totalShares() public view splitterInitialized returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view splitterInitialized returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view splitterInitialized returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view splitterInitialized returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view splitterInitialized returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual splitterInitialized {
        require(_shares[account] > 0, "PaymentSplitterCloneable: account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];

        require(payment != 0, "PaymentSplitterCloneable: account is not due payment");

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to all the payees which are owed Ether, according to their percentage of the
     * total shares and their previous withdrawals. Note: This function was not on the original OpenZeppelin contract.
     */
    function releaseAll() public virtual splitterInitialized {
        for (uint256 i = 0; i < _payees.length; i++) {
            address payable account = payable(_payees[i]);
            uint256 totalReceived = address(this).balance + _totalReleased;
            uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];
            if (payment == 0) {
                continue;
            }
            _released[account] = _released[account] + payment;
            _totalReleased = _totalReleased + payment;

            Address.sendValue(account, payment);
            emit PaymentReleased(account, payment);
        }
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private splitterInitialized {
        require(account != address(0), "PaymentSplitterCloneable: account is the zero address");
        require(shares_ > 0, "PaymentSplitterCloneable: shares are 0");
        require(_shares[account] == 0, "PaymentSplitterCloneable: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}
