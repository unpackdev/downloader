// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./Ownable.sol";

interface IVault {
    function receiveEarlyDeposits(uint256 amount) external;
}

/// @notice Kairos NFT index token early deposit contract, deposit now to get a boosted position when the index launches
///     This contract is used as a public deal offer to join the Kairos NFT index early, the offer goes as follows:
///     The public can deposit as much as desired until a limit date, after which the core team has a limited time to
///     publicly submit the vault contract, which will actually manage the index. The public can freely deposit and
///     withdraw until the vault is submitted, during the implementation period, deposits and withdraw are disabled.
///     Once the vault is submitted, the public can review it for a limited time, time during which whithdraws are
///     enabled. After the review period, anyone can transfer remaining deposits to the vault. The core team
///     can abort the program at any time, in which case the public can withdraw their deposits.
contract DepositEarly is Ownable {
    /// @notice Once the limit deposit time has passed, max time the core team has to implement the vault
    uint256 public constant MAX_IMPLEMENTATION_TIME = 90 days;
    /// @notice Once the vault is published, min time the public has to review it before deposits are transferred
    uint256 public constant MIN_PUBLIC_AUDIT_TIME = 7 days;
    /// @notice ERC20 token used for deposits
    IERC20 public immutable vaultCurrency;
    /// @notice amount deposited (possibly claimable) by address
    mapping(address => uint256) public amountDepositedBy;
    /// @notice total amount deposited held in contract
    uint256 public totalDeposited;
    /// @notice date after which deposits are no longer accepted, may be extended by the owner
    uint256 public depositLimitDate;
    /// @notice date on which the vault were publicly submitted
    /// @dev the date is 0 until the vault is submitted
    uint256 public vaultSubmitDate;
    /// @notice address of the vault contract
    IVault public vault;
    /// @notice whether the program was aborted by the owner, in which case the public can withdraw their deposits
    bool public programAborted;
    /// @notice whether the funds were transferred to the vault, ending the early deposit program
    bool public fundsWereTransferred;

    /// @notice emitted when a deposit is made
    /// @param from address of the depositor
    /// @param amount amount deposited
    event Deposited(address indexed from, uint256 amount);

    /// @notice emitted when a deposit is withdrawn
    /// @param from address of the withdrawer
    /// @param amount amount withdrawn
    event Withdrawn(address indexed from, uint256 amount);

    error WithdrawAmountExceedsBalance(uint256 amount, uint256 balance);
    error DepositLimitPassed(uint256 depositLimitDate);
    error DepositPeriodIsStillActive(uint256 depositLimitDate);
    error VaultReviewPeriodIsStillActive(uint256 vaultSubmitDate);
    error ImplementationTimeExceeded();
    error VaultNotSubmitted();
    error VaultIsAlreadySubmitted();
    error VaultIsActive();
    error ProgramAborted();
    error NewDepositDateIsBeforeOldOne();

    constructor(IERC20 _vaultCurrency, uint256 _depositLimitDate, address _owner) {
        vaultCurrency = _vaultCurrency;
        depositLimitDate = _depositLimitDate;
        transferOwnership(_owner);
    }

    modifier programNotAborted() {
        if (programAborted) revert ProgramAborted();
        _;
    }

    /// @notice deposit tokens to the early deposit program
    /// @param amount amount to deposit
    function deposit(uint256 amount) external programNotAborted {
        if (block.timestamp > depositLimitDate) revert DepositLimitPassed(depositLimitDate);
        amountDepositedBy[msg.sender] += amount;
        totalDeposited += amount;
        vaultCurrency.transferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    /// @notice withdraw tokens from the early deposit program
    /// @param amount amount to withdraw
    function withdraw(uint256 amount) external {
        uint256 callerBalance = amountDepositedBy[msg.sender];
        if (amount > callerBalance) revert WithdrawAmountExceedsBalance(amount, callerBalance);
        checkDepositsAreWhithdrawable();
        amountDepositedBy[msg.sender] -= amount;
        totalDeposited -= amount;
        vaultCurrency.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function transferDepositsToVault() external programNotAborted {
        if (address(vault) == address(0)) revert VaultNotSubmitted();
        if (block.timestamp <= vaultSubmitDate + MIN_PUBLIC_AUDIT_TIME)
            revert VaultReviewPeriodIsStillActive(vaultSubmitDate);
        if (fundsWereTransferred) revert VaultIsActive();
        fundsWereTransferred = true;
        vaultCurrency.transfer(address(vault), totalDeposited);
        vault.receiveEarlyDeposits(totalDeposited);
    }

    // ~~~ admin methods ~~~ //

    function extendDepositPeriod(uint256 newDepositLimitDate) external onlyOwner programNotAborted {
        if (newDepositLimitDate <= depositLimitDate) revert NewDepositDateIsBeforeOldOne();
        if (block.timestamp > depositLimitDate) revert DepositLimitPassed(depositLimitDate);
        depositLimitDate = newDepositLimitDate;
    }

    function submitVault(address _vault) external onlyOwner programNotAborted {
        if (block.timestamp <= depositLimitDate) revert DepositPeriodIsStillActive(depositLimitDate);
        if (block.timestamp > depositLimitDate + MAX_IMPLEMENTATION_TIME) revert ImplementationTimeExceeded();
        if (address(vault) != address(0)) revert VaultIsAlreadySubmitted();
        vaultSubmitDate = block.timestamp;
        vault = IVault(_vault);
    }

    function abortProgram() external onlyOwner programNotAborted {
        if (fundsWereTransferred) revert VaultIsActive();
        programAborted = true;
    }

    // ~~~ interal methods ~~~ //

    function checkDepositsAreWhithdrawable() internal view {
        if (programAborted) return;
        if (block.timestamp <= depositLimitDate) return;
        if (vaultSubmitDate == 0) {
            if (block.timestamp > depositLimitDate + MAX_IMPLEMENTATION_TIME) {
                return;
            } else {
                revert VaultNotSubmitted();
            }
        } else {
            if (fundsWereTransferred) {
                revert VaultIsActive();
            } else {
                return;
            }
        }
    }
}
