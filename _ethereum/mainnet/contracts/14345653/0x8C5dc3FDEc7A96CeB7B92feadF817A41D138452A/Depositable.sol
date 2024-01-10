// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

/** @title Depositable.
@dev It is a contract that allow to deposit an ERC20 token
*/
abstract contract Depositable is Initializable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // Map of deposits per address
    mapping(address => uint256) private _deposits;

    // the deposited token
    IERC20Upgradeable public depositToken;

    // the total amount deposited
    uint256 public totalDeposit;

    /**
     * @dev Emitted when `amount` tokens are deposited to account (`to`)
     * Note that `amount` may be zero.
     */
    event Deposit(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are withdrawn to account (`to`)
     * Note that `amount` may be zero.
     */
    event Withdraw(address indexed to, uint256 amount);

    /**
     * @dev Emitted when the deposited token is changed by the admin
     */
    event DepositTokenChange(address indexed token);

    /**
     * @notice Intializer
     * @param _depositToken: the deposited token
     */
    function __Depositable_init(IERC20Upgradeable _depositToken)
        internal
        onlyInitializing
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Depositable_init_unchained(_depositToken);
    }

    function __Depositable_init_unchained(IERC20Upgradeable _depositToken)
        internal
        onlyInitializing
    {
        depositToken = _depositToken;
    }

    /**
     * @dev Handle the deposit (transfer) of `amount` tokens from the `from` address
     * The contract must be approved to spend the tokens from the `from` address before calling this function
     * @param from: the depositor address
     * @param to: the credited address
     * @param amount: amount of token to deposit
     * @return the amount deposited
     */
    function _deposit(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (uint256) {
        // transfer tokens and check the real amount received
        uint256 balance = depositToken.balanceOf(address(this));
        depositToken.safeTransferFrom(from, address(this), amount);
        uint256 newBalance = depositToken.balanceOf(address(this));

        amount = newBalance - balance;
        _deposits[to] = _deposits[to].add(amount);
        totalDeposit = totalDeposit.add(amount);

        emit Deposit(from, to, amount);
        return amount;
    }

    /**
     * @dev Remove `amount` tokens from the `to` address deposit balance, and transfer the tokens to the `to` address
     * @param to: the destination address
     * @param amount: amount of token to deposit
     * @return the amount withdrawn
     */
    function _withdraw(address to, uint256 amount)
        internal
        virtual
        returns (uint256)
    {
        require(amount <= _deposits[to], "Depositable: amount too high");

        _deposits[to] = _deposits[to].sub(amount);
        totalDeposit = totalDeposit.sub(amount);
        depositToken.safeTransfer(to, amount);

        emit Withdraw(to, amount);
        return amount;
    }

    /**
     * @notice get the total amount deposited by an address
     */
    function depositOf(address _address) public view virtual returns (uint256) {
        return _deposits[_address];
    }

    /**
     * @notice Change the deposited token
     */
    function changeDepositToken(IERC20Upgradeable _depositToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(totalDeposit == 0, "Depositable: total deposit != 0");
        depositToken = _depositToken;

        emit DepositTokenChange(address(_depositToken));
    }

    uint256[50] private __gap;
}
