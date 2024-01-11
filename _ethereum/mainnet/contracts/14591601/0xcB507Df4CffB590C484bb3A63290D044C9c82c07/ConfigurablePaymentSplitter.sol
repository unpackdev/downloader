// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title ConfigurablePaymentSplitter
 * @dev Modified version of OpenZeppelin's PaymentSplitter contract. This contract allows to split Token payments
 * among a group of accounts. The sender does not need to be aware that the Token will be split in this way, since
 * it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares.
 *
 * The actual transfer is triggered as a separate function.
 */
contract ConfigurablePaymentSplitter is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal _totalShares;

    mapping(address => uint256) internal _shares;
    address[] internal _payees;

    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account);
    event PaymentReleased(uint256 amount);
    event ERC20PaymentReleased(address indexed token, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    /**
     * @dev Creates an instance of `TokenPaymentSplitter` where each account in `payees` is assigned the number
     * of shares at the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function initialize(address[] memory payees, uint256[] memory shares_) public initializer {
        __Ownable_init();
        require(
            payees.length == shares_.length,
            "ConfigurableTokenPaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "ConfigurableTokenPaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        require(
            _payees.length >= 1,
            "ConfigurableTokenPaymentSplitter: There are no payees"
        );
        return _payees[index];
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function release() public {
        uint256 totalPayeeAmount = address(this).balance;
        // Transfers contract's native coin balance to reward payee address(es).
        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payeeAmount = (totalPayeeAmount * _shares[_payees[i]]) /
                _totalShares;
            (bool success, ) = payable(_payees[i]).call{
                value: payeeAmount
            }("");
            require(success, "TRANSFER_FAILED");
        }
        emit PaymentReleased(totalPayeeAmount);
    }

    function release(address token) public {
        uint256 totalPayeeAmount = IERC20Upgradeable(token).balanceOf(address(this));
        // Transfers contract's token balance to reward payee address(es).
        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payeeAmount = (totalPayeeAmount * _shares[_payees[i]]) /
                _totalShares;
            IERC20Upgradeable(token).safeTransfer(_payees[i], payeeAmount);
        }
        emit ERC20PaymentReleased(token, totalPayeeAmount);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function addPayee(address account, uint256 shares_) public onlyOwner {
        require(
            account != address(0),
            "ConfigurableTokenPaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "ConfigurableTokenPaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "ConfigurableTokenPaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Remove an existing payee from the contract.
     * @param account The address of the payee to remove.
     * @param index The position of the payee in the _payees array.
     */
    function removePayee(address account, uint256 index) public onlyOwner {
        require(
            index < _payees.length,
            "ConfigurableTokenPaymentSplitter: index not in payee array"
        );
        require(
            account == _payees[index],
            "ConfigurableTokenPaymentSplitter: account does not match payee array index"
        );

        _totalShares = _totalShares - _shares[account];
        _shares[account] = 0;
        _payees[index] = _payees[_payees.length - 1];
        _payees.pop();
        emit PayeeRemoved(account);
    }
}
