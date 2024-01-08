// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";

/**
 * A contract that locks QUARTZ in exchange for freshly minted vestedQUARTZ
 * Meant to be used to give away rewards that then get subject to vesting rules.
 *
 * @notice A start date and a duration are specified on deploy. Before the
 * start date, QUARTZ may be sent to the contract, to mint vestedQUARTZ. Once
 * `start` is reached, no deposits are allowed (to prevent mistakes), and
 * withdrawals are now enabled. Withdrawal limits increase linearly during
 * `duration`, so that after the final end date, holders of vestedQUARTZ are
 * able to exchange 100% of it for QUARTZ.
 *
 * @notice In order to prevent users from circumventing the vesting logic,
 * we block outgoing transfer for any account that has redeemed vestedQUARTZ.
 * This prevents redeemers from redeeming in the middle of the period,
 * then sending remaining tokens to a separate wallet, where they'd be able to
 * redeem an extra share again (effectively being able to redeem 75% when only
 * 50% would be allowed)
 *
 * @notice Quartz can only be redeemed by user-accounts, not contracts. This is implemented to prevent staking contracts and other Dapps from maliciously redeeming user tokens
 */
contract VestedRewards is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public immutable quartz;
    uint64 public immutable start;
    uint64 public immutable duration;
    uint64 public immutable gracePeriod;

    mapping(address => uint256) public withdrawals;

    // useful to keep 2 decimal precision when dealing with percentages
    uint64 constant MUL = 10000;

    // start                  50%                     100%
    // G 100
    // N 50

    /**
     * @param _quartz the address of the QUARTZ token contract
     * @param _start timestamp at which withdrawals are enabled
     * @param _duration time (in seconds) it takes for vesting to allow full withdrawals
     * @param _gracePeriod time (in seconds) after the original duration until
     * admin clawback actions are enabled
     */
    constructor(
        IERC20 _quartz,
        uint64 _start,
        uint64 _duration,
        uint64 _gracePeriod
    ) ERC20("Sandclock (vested rewards)", "vestedQUARTZ") {
        require(_start > block.timestamp, "start date cannot be in the past");
        require(_duration > 0, "duration cannot be 0");
        require(_gracePeriod > 0, "gracePeriod cannot be 0");

        quartz = _quartz;
        start = _start;
        duration = _duration;
        gracePeriod = _gracePeriod;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(ERC20) {
        //slither-disable-next-line incorrect-equality
        require(
            withdrawals[sender] == 0,
            "outgoing transfers are locked for this account"
        );

        super._transfer(sender, recipient, amount);
    }

    /**
     * Locks QUARTZ into the contract, in exchange for an equal amount of freshly minted vestedQUARTZ
     *
     * @notice Can only be called before the specified start date
     *
     * @param _amount Amount of QUARTZ to lock
     */
    function deposit(uint256 _amount) external onlyBeforeStart {
        quartz.safeTransferFrom(_msgSender(), address(this), _amount);

        _mint(_msgSender(), _amount);
    }

    /**
     * Burns vestedQUARTZ from the sender's balance, and transfers him an
     * equal amount of QUARTZ
     *
     * @notice Can only be called after the specified start date
     *
     * @notice Amount to transfer is given the sender's current
     * vestedQUARTZ balance, and restricted by vesting rules
     *
     * @notice Withdrawing blocks future outgoing transfers from this account
     */
    function withdraw() external onlyAfterStart {
        _withdraw(_msgSender());
    }

    /**
     * Burns vestedQUARTZ from a given beneficiary's balance, and transfers him
     * an equal amount of QUARTZ
     *
     * @notice Can only be called after the specified start date
     *
     * @notice Amount to transfer is given the beneficiary's current
     * vestedQUARTZ balance, and restricted by vesting rules
     *
     * @notice Can only be called by the owner, to force rewards to be
     * redeemed if necessary
     *
     * @notice Withdrawing blocks future outgoing transfers from this account
     *
     * @param _beneficiary Beneficiary account to withdraw from
     */
    function withdrawFor(address _beneficiary)
        external
        onlyAfterStart
        onlyOwner
    {
        _withdraw(_beneficiary);
    }

    /**
     * Once grace period is over, allows owner to retrieve back any remaining quartz
     * and selfdestruct the contract
     */
    function clawback() external onlyAfterGracePeriod onlyOwner {
        uint256 balance = quartz.balanceOf(address(this));
        quartz.safeTransfer(_msgSender(), balance);

        selfdestruct(payable(_msgSender()));
    }

    /**
     * Calculates how much vestedQUARTZ can be currently redeemed by a beneficiary
     *
     * @notice If start date hasn't been reached yet, or if beneficiary is a contract, withdrawable amount is always 0.
     *
     * @param _beneficiary Beneficiary account
     */
    function withdrawable(address _beneficiary) public view returns (uint256) {
        if (!_started() || _beneficiary.isContract()) {
            return 0;
        }

        uint256 balance = balanceOf(_beneficiary);
        uint256 withdrawn = withdrawals[_beneficiary];

        uint256 unlocked = ((balance + withdrawn) * _durationPercent()) / MUL;

        if (unlocked <= withdrawn) {
            unlocked = 0;
        } else {
            unchecked {
                unlocked -= withdrawn;
            }
        }

        if (unlocked > balance) {
            unlocked = balance;
        }

        return unlocked;
    }

    /**
     * Burns an amount of vestedQUARTZ from beneficiary, and sends him
     * a corresponding amount of QUARTZ
     *
     * @notice Marks the beneficiary as redeemer, which blocks future outgoing
     * transfers from him
     */
    function _withdraw(address _beneficiary) private {
        uint256 amount = withdrawable(_beneficiary);
        require(amount > 0, "nothing to withdraw");

        _burn(_beneficiary, amount);

        withdrawals[_beneficiary] += amount;

        quartz.safeTransfer(_beneficiary, amount);
    }

    /**
     * Calculates the percentage of the timespan given by `start` and `duration`
     *
     * @notice Return value is multiplied by `MUL`, so as to keep precision.
     * Any calculation from this value must later be divided by `MUL` to
     * retrieve the original value
     */
    function _durationPercent() private view returns (uint64) {
        uint64 timestamp = _getBlockTimestamp();

        if (timestamp < start) {
            return 0;
        }

        if (timestamp >= _end()) {
            return MUL;
        }

        return ((timestamp - start) * MUL) / duration;
    }

    function _end() private view returns (uint256) {
        return start + duration;
    }

    function _started() private view returns (bool) {
        return start <= _getBlockTimestamp();
    }

    modifier onlyBeforeStart() {
        require(!_started(), "already started");
        _;
    }

    modifier onlyAfterStart() {
        require(_started(), "not started yet");
        _;
    }

    modifier onlyAfterGracePeriod() {
        require(
            (_end() + gracePeriod) <= block.timestamp,
            "grace period not over yet"
        );
        _;
    }

    function _getBlockTimestamp() private view returns (uint64) {
        return uint64(block.timestamp);
    }
}
