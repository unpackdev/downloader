// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./Ownable.sol";
import "./Math.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Percent.sol";

/// Lock rewards for advisors to be be withdrawn at later dates
contract AdvisorRewards is Ownable {
    using SafeERC20 for IERC20;

    struct Advisor {
        uint256 initialBalance;
        uint256 withdrawn;
    }

    /**
     * Withdraw phase determines `helixToken` withdrawals by advisors
     *  NoWithdraw:     default on contract creation, withdrawals are prohibited
     *  Withdraw0:      set by the owner, withdrawals are prohibited
     *  Withdraw50:     withdraw up to 50% of initial balance
     *  Withdraw100:    withdraw up to 100% of initial balance
     */
    enum WithdrawPhase {
        NoWithdraw,
        Withdraw0,
        Withdraw50,
        Withdraw100
    }
    
    /// Token being distributed to advisors
    address public helixToken;

    /// Current withdraw phase, dictates what percentage of tokens may be withdrawn
    WithdrawPhase public withdrawPhase;

    /// Length of withdrawPhase in seconds
    uint256 public immutable WITHDRAW_PHASE_DURATION; 

    /// Timestamp after which the current withdrawPhase has ended
    uint256 public withdrawPhaseEndTimestamp;

    /// Map the advisors address to their balances
    mapping(address => Advisor) public advisors;
    
    /// Map the withdrawPhase to the percent of balance an advisor may withdraw during that phase
    mapping (uint256 => uint256) public withdrawPhasePercent;

    // Emitted when tickets are withdrawn
    event Withdraw(address indexed user, uint256 amount, uint256 remainingBalance);

    // Emitted when the purchase phase is set
    event SetWithdrawPhase(WithdrawPhase withdrawPhase, uint256 startTimestamp, uint256 endTimestamp);

    // Emitted when adding new advisors
    event AddAdvisors(address indexed owner, address[] indexed advisors, uint256[] indexed balances);

    // Thrown when two arrays should be the same length but aren't
    error ArrayLengthMismatch(uint256 arrayA, uint256 arrayB);

    // Thrown when the sum of advisor balances exceeds the contract helix token balance
    error BalanceSumExceedsHelixTokenBalance();

    // Thown when trying to withdraw more than the max 
    error AmountExceedsMax(uint256 amount, uint256 max);

    // Thrown when trying to withdraw 0
    error ZeroWithdrawAmount();

    // Thrown when trying to withdraw during NoWithdraw phase
    error WithdrawForbidden();

    // Thrown when trying to assign an address to 0
    error ZeroAddress();
    
    modifier withdrawPermitted() {
        if (withdrawPhase == WithdrawPhase.NoWithdraw) {
            revert WithdrawForbidden();
        }
        _;
    }

    constructor(address _helixToken, uint256 _WITHDRAW_PHASE_DURATION) {
        if (_helixToken == address(0)) revert ZeroAddress();
        helixToken = _helixToken;

        WITHDRAW_PHASE_DURATION = _WITHDRAW_PHASE_DURATION;

        withdrawPhasePercent[2] = 50;       // 50%
        withdrawPhasePercent[3] = 100;      // 100%
    }

    /// Add advisors and set their initial balances
    function addAdvisors(address[] calldata _advisors, uint256[] calldata _balances) 
        external 
        onlyOwner 
    {
        uint256 advisorsLength = _advisors.length;
        if (advisorsLength != _balances.length) {
            revert ArrayLengthMismatch(advisorsLength, _balances.length);
        }

        uint256 balanceSum;
        for (uint256 i = 0; i < advisorsLength; i++) {
            address advisor = _advisors[i];
            if (advisor == address(0)) revert ZeroAddress();

            uint256 balance = _balances[i];

            balanceSum += balance;
            if (balanceSum > helixTokenBalance()) {
                revert BalanceSumExceedsHelixTokenBalance();
            }

            advisors[advisor].initialBalance = balance;
        }

        emit AddAdvisors(msg.sender, _advisors, _balances);
    }

    /// Withdraw _amount of helixToken to caller's address
    function withdraw(uint256 _amount) external {
        updateWithdrawPhase();

        _requireValidWithdraw(msg.sender, _amount);

        advisors[msg.sender].withdrawn += _amount;
        IERC20(helixToken).safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount, getBalance(msg.sender));
    }

    /// Called by the owner to manually set the withdraw phase
    /// Must be called to transition from NoWithdraw to Withdraw0
    function setWithdrawPhase(WithdrawPhase _withdrawPhase) external onlyOwner {
        _setWithdrawPhase(_withdrawPhase);
    }

    /// Withdraw the contract helix token balance to the caller
    function emergencyWithdraw() external onlyOwner {
        uint256 amount = helixTokenBalance();
        IERC20(helixToken).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, helixTokenBalance());
    }

    /// Return true if _by can withdraw _amount and revert otherwise
    function canWithdraw(address _by, uint256 _amount) external view returns (bool) {
        _requireValidWithdraw(_by, _amount);
        return true;
    }

    /// Return the _advisor
    function getAdvisor(address _advisor) 
        external 
        view 
        returns (uint256 initialBalance, uint256 withdrawn) 
    {
        Advisor memory advisor = advisors[_advisor];
        return (advisor.initialBalance, advisor.withdrawn);
    }

    /// Called periodically and, if enough time has elapsed, update the withdrawPhase
    function updateWithdrawPhase() public {
        if (block.timestamp >= withdrawPhaseEndTimestamp) {
            if (withdrawPhase == WithdrawPhase.Withdraw0) {
                _setWithdrawPhase(WithdrawPhase.Withdraw50);
            }
            else if (withdrawPhase == WithdrawPhase.Withdraw50) {
                _setWithdrawPhase(WithdrawPhase.Withdraw100);
            }
        }
    }

    /// Return maxAmount that _by can withdraw
    function getMaxAmount(address _by) public view withdrawPermitted returns (uint256 maxAmount) {
        // Use the next withdrawPhase if update hasn't been called
        uint256 _withdrawPhase = uint(withdrawPhase);
        if (
            block.timestamp >= withdrawPhaseEndTimestamp && 
            withdrawPhase != WithdrawPhase.Withdraw100
        ) {
            _withdrawPhase++;
        }

        // Get the max amount permitted by the current phase
        maxAmount = Percent.getPercentage(
            advisors[_by].initialBalance, 
            withdrawPhasePercent[_withdrawPhase]
        );

        // Reduce the max by the amount already withdrawn
        maxAmount -= advisors[_by].withdrawn;

        // Limit maxAmount by the advisor's balance
        maxAmount = Math.min(getBalance(_by), maxAmount);
    }

    /// Return _advisor un-withdrawn balance
    function getBalance(address _advisor) public view returns(uint256) {
        if (advisors[_advisor].initialBalance != 0) {
            return advisors[_advisor].initialBalance - advisors[_advisor].withdrawn;
        } else {
            return 0;
        }
    }

    /// Return this contract's helixToken balance
    function helixTokenBalance() public view returns(uint256 balance) {
        balance = IERC20(helixToken).balanceOf(address(this));
    }

    // Called to set the _withdrawPhase
    function _setWithdrawPhase(WithdrawPhase _withdrawPhase) private {
        withdrawPhase = _withdrawPhase;
        withdrawPhaseEndTimestamp = block.timestamp + WITHDRAW_PHASE_DURATION;
        emit SetWithdrawPhase(_withdrawPhase, block.timestamp, withdrawPhaseEndTimestamp);
    }

    // Require that _by can withdraw _amount of helixToken
    function _requireValidWithdraw(address _by, uint256 _amount) private view withdrawPermitted {
        if (_amount <= 0) revert ZeroWithdrawAmount();
        uint256 maxAmount = getMaxAmount(_by);
        if (_amount > maxAmount) revert AmountExceedsMax(_amount, maxAmount);
    }
} 
