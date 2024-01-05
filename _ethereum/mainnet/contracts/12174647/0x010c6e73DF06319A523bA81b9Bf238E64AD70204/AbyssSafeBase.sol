// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./IAbyssLockup.sol";

/**
 * Abyss Finance's AbyssSafeBase Contract
 * The main smart contract that is responsible for deposits and withdrawal of tokens.
 */
contract AbyssSafeBase is ReentrancyGuard, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    IERC20 public tokenContract;
    IAbyssLockup public lockupContract;
    uint256 private _unlockTime;
    uint256 private _abyssRequired;

    /**
     * @dev The parameter responsible for global disabling and enabling of new deposits.
     */
    bool public disabled;

    /**
     * @dev Here we store data for each locked token address of a specific wallet.
     *
     * - deposited - Amount of deposited tokens.
     * - requested - Amount of requested tokens for withdrawing.
     * - timestamp - Token deposit time or token unlock time established at an active withdrawal request
     */
    struct Data {
        uint256 deposited;
        uint256 divFactorDeposited;
        uint256 requested;
        uint256 divFactorRequested;
        uint256 timestamp;
    }

    /**
     * @dev Here we store data for every ever locked token on this smart contract.
     *
     * - disabled - A true value implies that this token cannot be deposited on the smart contract, while all other actions are allowed.
     * - approved - A true value implies that lockupContract is approved on transferFrom this smart contract.
     * - deposited - A total deposited token amount on the smart contract for the token address.
     * - requested - A total requested token amount from the smart contract.
     */
    struct Token {
        bool disabled;
        bool approved;
        uint256 deposited;
        uint256 divFactorDeposited;
        uint256 requested;
        uint256 divFactorRequested;
    }

    mapping (address => mapping (address => Data)) private _data;
    mapping (address => Token) private _tokens;

    /**
     * @dev Stores the amount of Abyss required for withdrawals after deposit for the caller's address.
     */
    mapping (address => uint256) private _rates;

    constructor(address token, address lockup, uint256 unlockTime_, uint256 abyssRequired_) {
        tokenContract = IERC20(address(token));
        lockupContract = IAbyssLockup(address(lockup));
        _unlockTime = unlockTime_;
        _abyssRequired = abyssRequired_;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Amount of Abyss required for service usage.
     */
    function abyssRequired() public view returns (uint256) {
        return _abyssRequired;
    }

    /**
     * @dev Amount of Abyss required for withdrawal requests and withdraw after deposit is made.
     */
    function rate(address account) public view returns (uint256) {
        return _rates[account];
    }

    /**
     * @dev Time of possible `token` withdrawal for the `account` if withdrawal request was made.
     * Time of `token` deposit if there were no withdrawal requests by the `account`.
     */
    function timestamp(address account, address token) public view returns (uint256) {
        return _data[account][token].timestamp;
    }

    /**
     * @dev Amount of `token` deposited by the `account`.
     */
    function deposited(address account, address token) public view returns (uint256) {
        return _data[account][token].deposited;
    }

    /**
     * @dev Amount of `token` requested for withdrawal by the `account`.
     */
    function requested(address account, address token) public view returns (uint256) {
        return _data[account][token].requested;
    }

    /**
     * @dev divFactor (rebase support) for specific `account` and `token` deposited.
     */
    function divFactorDeposited(address account, address token) public view returns (uint256) {
        return _data[account][token].divFactorDeposited;
    }

    /**
     * @dev divFactor (rebase support) for specific `account` and `token` requested.
     */
    function divFactorRequested(address account, address token) public view returns (uint256) {
        return _data[account][token].divFactorRequested;
    }

    /**
     * @dev Total mount of `token` deposited to this smart contract.
     */
    function totalDeposited(address token) public view returns (uint256) {
        return _tokens[token].deposited;
    }

    /**
     * @dev Total mount of `token` requested for withdrawal from this smart contract.
     */
    function totalRequested(address token) public view returns (uint256) {
        return _tokens[token].requested;
    }

    /**
     * @dev divFactor (rebase support) for specific `token` deposited.
     */
    function totalDivFactorDeposited(address token) public view returns (uint256) {
        return _tokens[token].divFactorDeposited;
    }

    /**
     * @dev divFactor (rebase support) for specific `token` requested.
     */
    function totalDivFactorRequested(address token) public view returns (uint256) {
        return _tokens[token].divFactorRequested;
    }

    /**
     * @dev Shows if specific `token` is disabled in this smart contract.
     */
    function isTokenDisabled(address token) public view returns (bool) {
        return _tokens[token].disabled;
    }

    /**
     * @dev Shows if specific `address` is a manager of this smart contract.
     */
    function isManager(address manager) public view returns (bool) {
        return _tokens[manager].approved;
    }

    /**
     * @dev Shows the unlock period that you need to wait after withdrawal request.
     */
    function unlockTime() external virtual view returns (uint256) {
        return _unlockTime;
    }

    // ACTION FUNCTIONS

    /**
     * @dev Moves `amount` of `token` from the caller's account to this smart contract.
     *
     * Requirements:
     *
     * - Contract is active and deposits for a specific token are not prohibited.
     * - Required Abyss amount is available on the account.
     * - Token smart contract has the right to move the tokens intended for deposit.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function deposit(address token, uint256 amount, address receiver) public nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(disabled == false && _tokens[token].disabled == false, "AbyssSafe: disabled");
        if (receiver == 0x0000000000000000000000000000000000000000) {
            receiver = msg.sender;
        }
        require(Address.isContract(receiver) == false, "AbyssSafe: receiver cannot be a smart contract");
        require(Address.isContract(token) == true, "AbyssSafe: token must be a smart contract");

        uint256 _tempFreeDeposits;

        if (_abyssRequired > 0 && token != address(tokenContract)) {
            _tempFreeDeposits = lockupContract.freeDeposits();
            require(_tempFreeDeposits > 0 || tokenContract.balanceOf(msg.sender) >= _abyssRequired, "AbyssSafe: not enough Abyss");
        }

        require(IERC20(address(token)).allowance(msg.sender, address(lockupContract)) > amount, "AbyssSafe: you need to approve token first");
        require(IERC20(address(token)).balanceOf(msg.sender) >= amount && amount > 0, "AbyssSafe: you cannot lock this amount");

        /**
         * @dev Verifies that the `lockupContract` has permission to move a given token located on this contract.
         */
        if (_tokens[token].approved == false) {

            /**
             * @dev Add permission to move `token` from this contract for `lockupContract`.
             */
            SafeERC20.safeApprove(IERC20(address(token)), address(lockupContract), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
            /**
             * @dev Verify that the permission was correctly applied to exclude any future uncertainties.
             */
            require(IERC20(address(token)).allowance(address(this), address(lockupContract)) > 0, "AbyssSafe: allowance issue");
            /**
             * @dev Add verification flag to improve efficiency and avoid revisiting the token smart contract, for gas economy.
             */
            _tokens[token].approved = true;
        }

        uint256 _tempBalanceSafe = IERC20(address(token)).balanceOf(address(this));

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tokens[token].deposited != _tempBalanceSafe) {
            if (_tokens[token].deposited > 0) {
                calcDivFactorDepositedTotal(token, _tempBalanceSafe);
            } else {
                lockupContract.externalTransfer(token, address(this), owner(), _tempBalanceSafe, 0);
                _tempBalanceSafe = 0;
            }
        }

        if (_tokens[token].divFactorDeposited == 0) {
            _tokens[token].divFactorDeposited = 1e36;
        }

        if (_data[receiver][token].divFactorDeposited == 0) {
            _data[receiver][token].divFactorDeposited = _tokens[token].divFactorDeposited;
        } else if (_data[receiver][token].divFactorDeposited != _tokens[token].divFactorDeposited) {
            calcDivFactorDeposited(receiver, token);
        }

        /**
         * @dev Writes down the cost of using the service so that any future amount requirement
         * increases won’t affect pre-existing users until they make a new deposit.
         */
        if (_tempFreeDeposits > 0) {
            _rates[receiver] = 0;
        } else {
            _rates[receiver] = _abyssRequired;
        }

        /**
         * @dev Moves `amount` of `token` from the caller's account to this smart contract with the help of `lockupContract` smart contract.
         */
        lockupContract.externalTransfer(token, msg.sender, address(this), amount, _abyssRequired);

        uint256 _tempBalanceSafeAfter = IERC20(address(token)).balanceOf(address(this));

        if (_tempBalanceSafe + amount != _tempBalanceSafeAfter) {
            amount = _tempBalanceSafeAfter - _tempBalanceSafe;
        }

        /**
         * @dev Increases the number of deposited User tokens.
         */
        _data[receiver][token].deposited = _data[receiver][token].deposited + amount;

        /**
         * @dev Changes the total amount of deposited tokens.
         */
        _tokens[token].deposited = _tokens[token].deposited + amount;

        emit Deposit(receiver, msg.sender, token, amount);
        return true;
    }

    /**
     * @dev Creates withdrawal request for the full amount of `token` deposited to this smart contract by the caller's account.
     *
     * Requirements:
     *
     * - Required Abyss amount is available on the account.
     * - There is no pending active withdrawal request for `token` by the caller's account.
     * - The caller has any amount of `token` deposited to this smart contract.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function request(address token, uint256 amount) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(
            _rates[msg.sender] == 0 ||
            token == address(tokenContract) ||
            tokenContract.balanceOf(msg.sender) >= _rates[msg.sender],
            "AbyssSafe: not enough Abyss");
        require(_data[msg.sender][token].requested == 0, "AbyssSafe: you already requested");
        require(_data[msg.sender][token].deposited > 0, "AbyssSafe: nothing to withdraw");

        uint256 _tempBalanceSafe = IERC20(address(token)).balanceOf(address(this));

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tokens[token].deposited != _tempBalanceSafe) {
                calcDivFactorDepositedTotal(token, _tempBalanceSafe);
        }

        if (_data[msg.sender][token].divFactorDeposited != _tokens[token].divFactorDeposited) {
            calcDivFactorDeposited(msg.sender, token);

            if (_data[msg.sender][token].deposited == 0) {
                delete _data[msg.sender][token].divFactorDeposited;
                delete _data[msg.sender][token].divFactorRequested;
                return true;
            }
        }

        uint256 _tempLockupBalance = IERC20(address(token)).balanceOf(address(lockupContract));
        uint256 _tempDepositedLockup = IAbyssLockup(address(lockupContract)).deposited(token);
        uint256 _tempLockupDivFactor = IAbyssLockup(address(lockupContract)).divFactor(token);

        if (_tempLockupBalance == 0) {
            delete _tokens[token].requested;
            delete _tokens[token].divFactorRequested;
            lockupContract.resetData(token);
        }
        if (_tempDepositedLockup != _tempLockupBalance) {
            if (_tempDepositedLockup > 0) {
                _tempLockupDivFactor = calcDivFactorLockup(_tempLockupDivFactor, _tempLockupBalance, _tempDepositedLockup);
            } else {
                lockupContract.externalTransfer(token, address(lockupContract), owner(), _tempLockupBalance, 0);
                _tempLockupBalance = 0;
            }
        }

        if (_tokens[token].divFactorRequested != _tempLockupDivFactor) {
            if (_tokens[token].divFactorRequested != 0) {
                _tokens[token].requested = _tokens[token].requested * _tempLockupDivFactor / _tokens[token].divFactorRequested;
            }
            _tokens[token].divFactorRequested = _tempLockupDivFactor;
        } else if (_tempLockupDivFactor == 0) {
            _tempLockupDivFactor = 1e36;
            _tokens[token].divFactorRequested = 1e36;
        }

        _data[msg.sender][token].divFactorRequested = _tokens[token].divFactorRequested;

        if (_data[msg.sender][token].deposited < amount || amount == 0) {
            amount = _data[msg.sender][token].deposited;
        }

        /**
         * @dev Changes the total amount of deposited `token` by the amount of withdrawing request in the decreasing direction.
         */
        _tokens[token].deposited = _tokens[token].deposited - amount;

        /**
         * @dev Changes the caller's amount of deposited `token` by the amount of withdrawing request in the decreasing direction.
         */
        if (amount == _data[msg.sender][token].deposited) {
            delete _data[msg.sender][token].deposited;
            delete _data[msg.sender][token].divFactorDeposited;
            if (_tokens[token].deposited == 0) {
                delete _tokens[token].divFactorDeposited;
            }
        } else {
            _data[msg.sender][token].deposited = _data[msg.sender][token].deposited - amount;
        }

        /**
         * @dev Sets a date for `lockupTime` seconds from the current date.
         */
        _data[msg.sender][token].timestamp = block.timestamp + _unlockTime;

        /**
         * @dev If `token` balance on this smart contract is greater than zero,
         * sends tokens to the 'lockupContract' smart contract.
         */
        lockupContract.externalTransfer(token, address(this), address(lockupContract), amount, 0);

        uint256 _tempLockupBalanceAfter = IERC20(address(token)).balanceOf(address(lockupContract));

        if (_tempLockupBalance + amount != _tempLockupBalanceAfter) {
            amount = _tempLockupBalanceAfter - _tempLockupBalance;
        }

        _tempLockupBalance = _tempLockupBalance + amount;

        lockupContract.updateData(token, _tempLockupBalance, _tempLockupDivFactor);

        /**
         * @dev Changes the total amount of requested `token by the sum of the withdrawing request in the increasing direction.
         */
        _tokens[token].requested = _tokens[token].requested + amount;

        /**
         * @dev The requested amount of the caller's tokens for withdrawal request becomes equal to the amount requested.
         */
        _data[msg.sender][token].requested = amount;

        _tempLockupBalance = _tempLockupBalance + amount;

        emit Request(msg.sender, token, amount, _data[msg.sender][token].timestamp);
        return true;
    }

    /**
     * @dev Cancels withdrawal request for the full amount of `token` requested from this smart contract by the caller's account.
     *
     * Requirement:
     *
     * - There is a pending active withdrawal request for `token` by the caller's account.
     */
    function cancel(address token) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(_data[msg.sender][token].requested > 0, "AbyssSafe: nothing to cancel");

        uint256 _tempAmount = _data[msg.sender][token].requested;

        uint256 _tempLockupBalance = IERC20(address(token)).balanceOf(address(lockupContract));
        uint256 _tempLockupBalance2;
        uint256 _tempBalanceSafe = IERC20(address(token)).balanceOf(address(this));
        uint256 _tempDepositedLockup = IAbyssLockup(address(lockupContract)).deposited(token);
        uint256 _tempLockupDivFactor = IAbyssLockup(address(lockupContract)).divFactor(token);
        uint256 _tempTimestamp = _data[msg.sender][token].timestamp;

        if (_tempLockupBalance == 0) {
            delete _data[msg.sender][token].requested;
            delete _data[msg.sender][token].divFactorRequested;
            delete _tokens[token].requested;
            delete _tokens[token].divFactorRequested;
            lockupContract.resetData(token);
            return true;
        }

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tokens[token].deposited != _tempBalanceSafe) {
            if (_tokens[token].deposited > 0) {
                calcDivFactorDepositedTotal(token, _tempBalanceSafe);
            } else {
                lockupContract.externalTransfer(token, address(this), owner(), _tempBalanceSafe, 0);
                _tempBalanceSafe = 0;
            }
        }

        if (_tokens[token].divFactorDeposited == 0) {
            _tokens[token].divFactorDeposited = 1e36;
        }

        if (_data[msg.sender][token].divFactorDeposited != _tokens[token].divFactorDeposited) {
            if (_data[msg.sender][token].divFactorDeposited == 0) {
                _data[msg.sender][token].divFactorDeposited = _tokens[token].divFactorDeposited;
            } else {
                calcDivFactorDeposited(msg.sender, token);
            }
        }

        if (_tempDepositedLockup != _tempLockupBalance) {
            _tempLockupDivFactor = calcDivFactorLockup(_tempLockupDivFactor, _tempLockupBalance, _tempDepositedLockup);
        }

        if (_tokens[token].divFactorRequested != _tempLockupDivFactor) {
            calcDivFactorRequestedTotal(token, _tempLockupDivFactor);
        }

        if (_data[msg.sender][token].divFactorRequested != _tokens[token].divFactorRequested) {
            _tempAmount = calcDivFactorRequested(_tempLockupDivFactor, _data[msg.sender][token].divFactorRequested, _tempAmount);

            if (_tokens[token].requested < _tempAmount) {
                _tempAmount = _tokens[token].requested;
            }
            _data[msg.sender][token].divFactorRequested = _tokens[token].divFactorRequested;
        }

        delete _data[msg.sender][token].divFactorRequested;

        /**
         * @dev Changes the total amount of requested `token` by the cancelation withdrawal amount in the decreasing direction.
         */
        _tokens[token].requested = _tokens[token].requested - _tempAmount;

        /**
         * @dev Removes `token` divFactor if balance of the requested `token` is 0 after withdraw cancelation.
         */
        if (_tokens[token].requested == 0) {
            delete _tokens[token].divFactorRequested;
        }

        /**
         * @dev Taking withdrawal request cancellation into account, restores the caller's `token` balance.
         */
        _data[msg.sender][token].deposited = _data[msg.sender][token].deposited + _tempAmount;

        /**
         * @dev Resets information on the number of `token` requested by the caller for withdrawal request.
         */
        delete _data[msg.sender][token].requested;

        /**
         * @dev Calculates the new balance of `token` on `lockup` smart contract.
         */
        _tempLockupBalance2 = _tempLockupBalance - _tempAmount;

        /**
         * @dev Removes divFactor on `lockup` smart contract if balane of the `token` is 0 after withdraw.
         */
        if (_tempLockupBalance2 == 0) {
            _tempLockupDivFactor = 1;
        }

        /**
         * @dev Reset the unblocking time to zero.
         */
        delete _data[msg.sender][token].timestamp;

        lockupContract.externalTransfer(token, address(lockupContract), address(this), _tempAmount, 0);
        lockupContract.updateData(token, _tempLockupBalance2, _tempLockupDivFactor);


        _tempLockupBalance2 = IERC20(address(token)).balanceOf(address(this));

        if (_tempBalanceSafe + _tempAmount != _tempLockupBalance2) {
            _tempAmount = _tempLockupBalance2 - _tempBalanceSafe;
        }

        /**
         * @dev Changes the total amount of deposited `token` by the amount of withdrawing request in the increasing direction.
         */
        _tokens[token].deposited = _tokens[token].deposited + _tempAmount;

        emit Cancel(msg.sender, token, _tempAmount, _tempTimestamp);
        return true;
    }

    /**
     * @dev Withdraws the full amount of `token` requested from this smart contract by the caller's account.
     *
     * Requirement:
     *
     * - Required Abyss amount is available on the account.
     * - There is pending active withdrawal request for `token` by the caller's account.
     * - Required amount of time has already passed since withrawal request execution.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function withdraw(address token) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(
            _rates[msg.sender] == 0 ||
            token == address(tokenContract) ||
            tokenContract.balanceOf(msg.sender) >= _rates[msg.sender],
            "AbyssSafe: not enough Abyss");
        require(_data[msg.sender][token].requested > 0, "AbyssSafe: request withdraw first");
        require(_data[msg.sender][token].timestamp <= block.timestamp, "AbyssSafe: patience you must have!");

        uint256 _tempAmount = _data[msg.sender][token].requested;
        uint256 _tempLockupBalance = IERC20(address(token)).balanceOf(address(lockupContract));
        uint256 _tempLockupBalance2;
        uint256 _tempDepositedLockup = IAbyssLockup(address(lockupContract)).deposited(token);
        uint256 _tempLockupDivFactor = IAbyssLockup(address(lockupContract)).divFactor(token);

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tempLockupBalance == 0) {
            delete _data[msg.sender][token].requested;
            delete _data[msg.sender][token].divFactorRequested;
            delete _tokens[token].requested;
            delete _tokens[token].divFactorRequested;
            lockupContract.resetData(token);
            return true;
        }

        if (_tempDepositedLockup != _tempLockupBalance) {
            _tempLockupDivFactor = calcDivFactorLockup(_tempLockupDivFactor, _tempLockupBalance, _tempDepositedLockup);
        }

        if (_tokens[token].divFactorRequested != _tempLockupDivFactor) {
            calcDivFactorRequestedTotal(token, _tempLockupDivFactor);
        }

        if (_data[msg.sender][token].divFactorRequested != _tokens[token].divFactorRequested) {
            _tempAmount = calcDivFactorRequested(_tempLockupDivFactor, _data[msg.sender][token].divFactorRequested, _tempAmount);

            if (_tokens[token].requested < _tempAmount) {
                _tempAmount = _tokens[token].requested;
            }

        }

        delete _data[msg.sender][token].divFactorRequested;

        /**
         * @dev Changes the total amount of requested `token` by the cancelation withdrawal amount in the decreasing direction.
         */
        _tokens[token].requested = _tokens[token].requested - _tempAmount;

        /**
         * @dev Removes `token` divFactor if balance of the requested `token` is 0 after withdraw.
         */
        if (_tokens[token].requested == 0) {
            delete _tokens[token].divFactorRequested;
        }

        /**
         * @dev Removes information about amount of requested `token`.
         */
        delete _data[msg.sender][token].requested;

        if (_tempAmount == 0) {
            delete _data[msg.sender][token].timestamp;
            return true;
        }

        /**
         * @dev Calculates the new balance of token on lockup smart contract.
         */
        _tempLockupBalance2 = _tempLockupBalance - _tempAmount;

        /**
         * @dev Removes divFactor on `lockup` smart contract if balane of the `token` is 0 after withdraw.
         */
        if (_tempLockupBalance2 == 0) {
            _tempLockupDivFactor = 1;
        }

        /**
         * @dev Withdraws tokens to the caller's address.
         */
        lockupContract.externalTransfer(token, address(lockupContract), msg.sender, _tempAmount, 0);
        lockupContract.updateData(token, _tempLockupBalance2, _tempLockupDivFactor);

        _tempLockupBalance2 = IERC20(address(token)).balanceOf(address(lockupContract));

        if (_tempLockupBalance != _tempLockupBalance2 + _tempAmount) {
            _tempAmount = _tempLockupBalance - _tempLockupBalance2;
        }

        emit Withdraw(msg.sender, token, _tempAmount, _data[msg.sender][token].timestamp);

        /**
         * @dev Reset the unblocking time to zero.
         */
        delete _data[msg.sender][token].timestamp;
        return true;

    }

    // REBASE CALCULATION FUNCTIONS

    function calcDivFactorDepositedTotal(address _token, uint256 _balanceSafe) internal {
        _tokens[_token].divFactorDeposited = _tokens[_token].divFactorDeposited * _balanceSafe / _tokens[_token].deposited;
        _tokens[_token].deposited = _balanceSafe;
    }

    function calcDivFactorRequestedTotal(address _token, uint256 _lockupDivFactor) internal {
        _tokens[_token].requested = _tokens[_token].requested * _lockupDivFactor / _tokens[_token].divFactorRequested;
        _tokens[_token].divFactorRequested = _lockupDivFactor;
    }

    function calcDivFactorDeposited(address _owner, address _token) internal {
        _data[_owner][_token].deposited = _data[_owner][_token].deposited * _tokens[_token].divFactorDeposited / _data[_owner][_token].divFactorDeposited;
        _data[_owner][_token].divFactorDeposited = _tokens[_token].divFactorDeposited;
    }

    function calcDivFactorRequested(uint256 _lockupDivFactor, uint256 _divFactorRequested, uint256 _amount) internal pure returns (uint256) {
        return _amount * _lockupDivFactor / _divFactorRequested;
    }

    function calcDivFactorLockup(uint256 _lockupDivFactor, uint256 _lockupBalance, uint256 _lockupDeposited) internal pure returns (uint256) {
        return _lockupDivFactor * _lockupBalance / _lockupDeposited;
    }

    // ADMIN FUNCTIONS

    /**
     * @dev Initializes configuration of a given smart contract, with a specified
     * address for the `lockupContract` smart contract.
     *
     * This value is immutable: it can only be set once.
     */
    function initialize(address lockupContract_) external onlyOwner returns (bool) {
        require(address(lockupContract) == address(0), "AbyssSafe: already initialized");
        lockupContract = IAbyssLockup(lockupContract_);
        return true;
    }

    /**
     * @dev Configurates smart contract allowing modification in the amount of
     * required Abyss to use the smart contract.
     *
     * NOTE: The price for pre-existing users will remain unchanged until
     * a new token deposit is made. This aspect has been considered to prevent
     * possibility of increase pricing for already made deposits.
     *
     * Also, this function allows disabling of deposits, both globally and for a specific token.
     */
    function setup(address token, bool tokenDisabled, bool globalDisabled, uint256 abyssRequired_) external onlyManager(msg.sender) returns (bool) {
        disabled = globalDisabled;
        if (token != address(this)) {
            _tokens[token].disabled = tokenDisabled;
        }
        _abyssRequired = abyssRequired_;
        return true;
    }

    /**
     * @dev Allows the `owner` to assign managers who can use the setup function.
     */
    function setManager(address manager) external onlyOwner returns (bool) {

        if (_tokens[manager].approved == false) {
            _tokens[manager].approved = true;
        } else {
            _tokens[manager].approved = false;
        }
        return true;
    }

    /**
     * @dev A function that allows the `owner` to withdraw any locked and lost tokens
     * from the smart contract if such `token` is not yet deposited.
     *
     * NOTE: Embedded in the function is verification that allows for token withdrawal
     * only if the token balance is greater than the token balance deposited on the smart contract.
     */
    function withdrawLostTokens(address token) external onlyOwner returns (bool) {
        uint256 _tempBalance = IERC20(address(token)).balanceOf(address(this));

        if (_tokens[token].deposited == 0 && _tempBalance > 0) {
            SafeERC20.safeTransfer(IERC20(address(token)), msg.sender, _tempBalance);
        }

        return true;
    }

    /**
     * @dev A function that allows to set allowance between this and lockup smart contract if something went wrong.
     */
    function manualApprove(address token) external returns (bool) {
        SafeERC20.safeApprove(IERC20(address(token)), address(lockupContract), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        return true;
    }

    /**
     * @dev Modifier that prohibits execution of this smart contract from `token` address
     */
    modifier isAllowed(address account, address token) {
        require(account != token, "AbyssSafe: you shall not pass!");
        _;
    }

    /**
     * @dev Modifier that allows usage only for managers chosen by the `owner`.
    */
    modifier onlyManager(address account) {
        require(_tokens[account].approved || account == owner(), "AbyssSafe: you shall not pass!");
        _;
    }

    event Deposit(address indexed user, address indexed depositor, address token, uint256 amount);
    event Request(address indexed user, address token, uint256 amount, uint256 timestamp);
    event Cancel(address indexed user, address token, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, address token, uint256 amount, uint256 timestamp);
}
