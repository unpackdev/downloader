// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * PaymentSplitterLib authored by Bling Artist Lab
 * Version 0.2.0
 * 
 * This library is designed to work in conjunction with
 * PaymentSplitterFacet - it facilitates diamond storage and shared
 * functionality associated with PaymentSplitterFacet.
/**************************************************************/

import "./IERC20Upgradeable.sol";

library PaymentSplitterLib {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("paymentsplitter.storage");

    struct state {
        uint256 _totalShares;
        uint256 _totalReleased;

        mapping(address => uint256) _shares;
        mapping(address => uint256) _released;
        address[] _payees;

        mapping(IERC20Upgradeable => uint256) _erc20TotalReleased;
        mapping(IERC20Upgradeable => mapping(address => uint256)) _erc20Released;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) internal {
        PaymentSplitterLib.state storage s = PaymentSplitterLib.getState();

        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(s._shares[account] == 0, "PaymentSplitter: account already has shares");

        s._payees.push(account);
        s._shares[account] = shares_;
        s._totalShares = s._totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

/**************************************************************\
 * PaymentSplitterFacet authored by Bling Artist Lab
 * Version 0.3.0
 * 
 * Adapted from a contract by OpenZeppelin:
 * OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)
/**************************************************************/

import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterFacet is ContextUpgradeable {

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return PaymentSplitterLib.getState()._totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return PaymentSplitterLib.getState()._totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token) public view returns (uint256) {
        return PaymentSplitterLib.getState()._erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return PaymentSplitterLib.getState()._shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return PaymentSplitterLib.getState()._released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account) public view returns (uint256) {
        return PaymentSplitterLib.getState()._erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return PaymentSplitterLib.getState()._payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20Upgradeable token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        PaymentSplitterLib.state storage s = PaymentSplitterLib.getState();

        require(s._shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        s._totalReleased += payment;
        unchecked {
            s._released[account] += payment;
        }

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentSplitterLib.PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual {
        PaymentSplitterLib.state storage s = PaymentSplitterLib.getState();

        require(s._shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
        // If "_erc20TotalReleased[token] += payment" does not overflow, then "_erc20Released[token][account] += payment"
        // cannot overflow.
        s._erc20TotalReleased[token] += payment;
        unchecked {
            s._erc20Released[token][account] += payment;
        }

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit PaymentSplitterLib.ERC20PaymentReleased(token, account, payment);
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
        PaymentSplitterLib.state storage s = PaymentSplitterLib.getState();
        return (totalReceived * s._shares[account]) / s._totalShares - alreadyReleased;
    }
}