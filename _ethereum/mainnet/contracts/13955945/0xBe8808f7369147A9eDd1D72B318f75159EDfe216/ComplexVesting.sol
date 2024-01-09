// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/**
  @dev This contract is one of 3 vesting contracts for the JustCarbon Foundation

  Here, we cover the case of complex vesting contract with a nonLinear vesting schedule over a fixed time period

  @author jordaniza (jordan.imran@predixa.ai)
 */

contract ComplexVesting is Ownable, ReentrancyGuard {
    /* =============== Immutable variables ================= */

    // length of a vesting period
    uint256 public immutable vestingPeriodLength;

    // length of the interval to adjust the vesting rate,
    // in terms of vesting periods
    uint256 public immutable vestingPeriodsBeforeDecay;

    // qty by which to reduce the base vesting
    uint256 public immutable decayQty;

    // base vesting quantity over the decay interval
    uint256 public immutable baseQty;

    // address of the account who can interact with the contract
    address public immutable beneficiary;

    // start timestamp of vesting period for the account
    uint256 public immutable startTimestamp;

    // end timestamp of vesting period for the account
    uint256 public immutable endTimestamp;

    // the contract address of the token
    IERC20 private immutable token;

    /* ================ Mutable variables ================= */

    // balance of the contract
    uint256 public balance = 0;

    // total value already withdrawn by the account
    uint256 public withdrawn = 0;

    // Lifecycle flag to prevent adding beneficiaries after tokens have been deposited
    bool public tokensDeposited = false;

    // prevent contract interactions after withdraw method called
    bool public closed = false;

    /* ===== Events ===== */

    event DepositTokens(uint256 qty);
    event WithdrawSuccess(address benficiary, uint256 qty);
    event EmergencyWithdraw();

    /* ===== Constructor ===== */

    constructor(
        address _tokenAddress,
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _vestingPeriodLength,
        uint256 _vestingPeriodsBeforeDecay,
        uint256 _decayQty,
        uint256 _baseQty
    ) {
        require((_startTimestamp > block.timestamp), "Pass start in future");
        require(_endTimestamp > _startTimestamp, "End before start");
        require(_baseQty >= _decayQty, "Cannot decay more than base");
        require(
            (_vestingPeriodsBeforeDecay > 0) &&
                (_vestingPeriodLength > 0) &&
                (_decayQty > 0) &&
                (_baseQty > 0),
            "Pass positive quantities"
        );
        token = IERC20(_tokenAddress);
        beneficiary = _beneficiary;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        vestingPeriodLength = _vestingPeriodLength;
        vestingPeriodsBeforeDecay = _vestingPeriodsBeforeDecay;
        decayQty = _decayQty;
        baseQty = _baseQty;
    }

    /* ===== Modifiers ==== */

    modifier afterDeposit() {
        require(tokensDeposited, "Cannot call before deposit");
        _;
    }

    modifier notClosed() {
        require(!closed, "Contract closed");
        _;
    }

    /* ===== Getters and view functions ===== */

    /**
    Non linear vesting schedule that pays out progressively less per period, as time goes on.

    @dev Compute the cumulative amount vested by incrementing a `vestingAmount` variable.
    Each decayPeriod (eg. year), the amount vesting per period (eg. month) declines, according to the decay

        @param elapsedDecayPeriods is the number of whole "decay periods" the contract has been running - eg. 3 years
        @param elapsedCarryover is the completed vesting periods in the in the decay period - eg. 2 months
        @return the amount that has been vested over time
    */
    function _calculateVestingAmount(
        uint256 elapsedDecayPeriods,
        uint256 elapsedCarryover
    ) private view returns (uint256) {
        // initially set the vesting amount to zero
        uint256 vestingAmount = 0;

        // then, for every whole "decay period" that has passed (i.e. years):
        for (uint256 i; i <= elapsedDecayPeriods; i++) {
            // initialize the quantity vested in this period to zero
            uint256 periodVestingQty = 0;
            uint256 decayForPeriod = decayQty * i;

            // if decay would cause underflow, just set vesting quantity to zero
            if (decayForPeriod < baseQty) {
                // otherwise, get the per period vesting quantity (i.e monthly)
                periodVestingQty =
                    (baseQty - decayForPeriod) /
                    vestingPeriodsBeforeDecay;
            }
            // i is the period, if it's less than the elapsed, just take the whole period
            if (i < elapsedDecayPeriods) {
                vestingAmount += periodVestingQty * vestingPeriodsBeforeDecay;

                // otherwise, take the number of periods in the current decay period
            } else {
                vestingAmount += periodVestingQty * elapsedCarryover;
            }
        }
        return vestingAmount;
    }

    /**
        @return the amount owed to the beneficiary at a given point in time
    */
    function calculateWithdrawal() public view returns (uint256) {
        require(block.timestamp >= startTimestamp, "Vesting not started");
        if (block.timestamp >= endTimestamp) {
            return balance;
        }
        uint256 elapsedSeconds = block.timestamp - startTimestamp;

        // whole vesting periods completed i.e. 14 months
        uint256 elapsedWholePeriods = elapsedSeconds / vestingPeriodLength;

        // whole periods completed where, after each, rate of vesting decays i.e. 2 years
        uint256 elapsedDecayPeriods = elapsedWholePeriods /
            vestingPeriodsBeforeDecay;

        // whole vesting periods in the current "decay period" i.e. 2 months (into year 3)
        uint256 elapsedCarryover = elapsedWholePeriods -
            (elapsedDecayPeriods * vestingPeriodsBeforeDecay);
        uint256 vestingAmount = _calculateVestingAmount(
            elapsedDecayPeriods,
            elapsedCarryover
        );
        uint256 finalAmount = vestingAmount - withdrawn;
        if (finalAmount > balance) {
            return balance;
        }
        return finalAmount;
    }

    /**
      @dev Deposit tokens into the contract, that can then be withdrawn by the beneficiaries
     */
    function deposit(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, "Invalid amount");

        tokensDeposited = true;
        balance += amount;

        require(token.transferFrom(msg.sender, address(this), amount));
        emit DepositTokens(amount);

        return true;
    }

    /**
      @dev Transfer all tokens currently vested to the whitelisted account.  
     */
    function withdraw()
        public
        notClosed
        afterDeposit
        nonReentrant
        returns (bool)
    {
        require(msg.sender == beneficiary, "Only whitelisted");
        uint256 amount = calculateWithdrawal();
        require(amount > 0, "Nothing to withdraw");

        balance -= amount;
        withdrawn += amount;

        require(token.transfer(msg.sender, amount));

        emit WithdrawSuccess(msg.sender, amount);
        return true;
    }

    /**
      @dev Withdraw the full token balance of the contract to a the owner
      Used in the case of a discovered vulnerability.
     */
    function emergencyWithdraw() public onlyOwner returns (bool) {
        require(balance > 0, "No funds to withdraw");
        withdrawn += balance;
        balance = 0;
        closed = true;
        require(token.transfer(msg.sender, token.balanceOf(address(this))));
        emit EmergencyWithdraw();
        return true;
    }
}
