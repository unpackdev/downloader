// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IRewards.sol";
import "./IStaker.sol";
import "./ITokenMinter.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

/**
 * @title OceanDepositor
 * @author Convex / H2O
 *
 * Contract, that is the entrypoint of depositing Ocean for sake of converting it into veOcean.
 * Returns psdnOcean token to the user depositing Ocean.
 */
contract OceanDepositor {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ============ Constants ============= */

    uint256 private constant MAXTIME = 4 * 365 * 86400;
    uint256 private constant WEEK = 7 * 86400;
    uint256 public constant FEE_DENOMINATOR = 10000;

    /* ============ State Variables ============ */

    address public ocean;
    address public escrow;

    uint256 public lockIncentive = 10; //incentive to users who spend gas to lock ocean

    address public immutable staker;
    address public immutable minter;
    uint256 public incentiveOcean = 0;
    uint256 public unlockTime;

    // Permissions
    address public feeManager;

    /* ============ Modifiers ============ */

    modifier onlyFeeManager() {
        require(msg.sender == feeManager, "auth!");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Sets various contract addresses
     *
     * @param _staker                Address of VoterProxy contract
     * @param _minter                Address of psdnOcean contract
     * @param _ocean                 Address of ocean token
     * @param _escrow                 Address of veOcean contract
     */

    constructor(
        address _staker,
        address _minter,
        address _ocean,
        address _escrow
    ) {
        staker = _staker;
        minter = _minter;
        ocean = _ocean;
        escrow = _escrow;
        feeManager = msg.sender;
    }

    /* ============ External Functions ============ */

    /* ====== Setters ====== */

    /**
     * Sets fee manager address
     *
     * @param _feeManager            Address of the new fee manager
     */
    function setFeeManager(address _feeManager) external onlyFeeManager {
        feeManager = _feeManager;
    }

    /**
     * Sets punishment/reward for locking ocean on contract into veOcean
     *
     * @param _lockIncentive            Share of deposited amount, that will be used to reward caller of locking into veOcean
     */
    function setFees(uint256 _lockIncentive) external onlyFeeManager {
        if (_lockIncentive >= 0 && _lockIncentive <= 30) {
            lockIncentive = _lockIncentive;
        }
    }

    /* ====== Actions ====== */

    /**
     * Sets initial lock on Ocean tokens in veOcean contract. Sets time lock to maximum allowed lock time.
     */
    function initialLock() external onlyFeeManager {
        uint256 veocean = IERC20(escrow).balanceOf(staker);
        if (veocean == 0) {
            uint256 unlockAt = block.timestamp + MAXTIME;
            uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

            //release old lock if exists
            IStaker(staker).release();
            //create new lock
            uint256 oceanBalanceStaker = IERC20(ocean).balanceOf(staker);
            IStaker(staker).createLock(oceanBalanceStaker, unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    /**
     * Function for any user, that is willing to execute locking of Ocean, that is stored on this contract due to calling deposit function
     * with _lock parameter set to false (delegating responsibility of locking to person willing to do that)
     */
    function lockOcean() external {
        _lockOcean();

        //mint incentives
        if (incentiveOcean > 0) {
            ITokenMinter(minter).mint(msg.sender, incentiveOcean);
            incentiveOcean = 0;
        }
    }

    /**
     * Function for depositing ocean, in order to get psdnOcean
     * Can execute locking into veOcean immediately or defer locking to someone else by paying a fee.
     * While users can choose to lock or defer, this is mostly in place so that
     * the ocean reward contract isn't costly to claim rewards
     *
     * @param _amount                 Amount of Ocean token to deposit
     * @param _lock                   Flag, whether user wants to pay for locking or defer locking to someone else
     * @param _stakeAddress           Address of staking contract (RewardPool), in which newly minted psdnOcean should be staked
     *                                If set to zero address, then psdnOcean tokens are returned to the user instead.
     */
    function deposit(
        uint256 _amount,
        bool _lock,
        address _stakeAddress
    ) public {
        require(_amount > 0, "!>0");

        if (_lock) {
            //lock immediately, transfer directly to staker to skip an erc20 transfer
            IERC20(ocean).safeTransferFrom(msg.sender, staker, _amount);
            _lockOcean();
            if (incentiveOcean > 0) {
                //add the incentive tokens here so they can be staked together
                _amount = _amount.add(incentiveOcean);
                incentiveOcean = 0;
            }
        } else {
            //move tokens here
            IERC20(ocean).safeTransferFrom(msg.sender, address(this), _amount);
            //defer lock cost to another user
            uint256 callIncentive = _amount.mul(lockIncentive).div(
                FEE_DENOMINATOR
            );
            _amount = _amount.sub(callIncentive);

            //add to a pool for lock caller
            incentiveOcean = incentiveOcean.add(callIncentive);
        }

        bool depositOnly = _stakeAddress == address(0);
        if (depositOnly) {
            //mint for msg.sender
            ITokenMinter(minter).mint(msg.sender, _amount);
        } else {
            //mint here
            ITokenMinter(minter).mint(address(this), _amount);
            //stake for msg.sender
            IERC20(minter).safeApprove(_stakeAddress, 0);
            IERC20(minter).safeApprove(_stakeAddress, _amount);
            IRewards(_stakeAddress).stakeFor(msg.sender, _amount);
        }
    }

    function deposit(uint256 _amount, bool _lock) external {
        deposit(_amount, _lock, address(0));
    }

    function depositAll(bool _lock, address _stakeAddress) external {
        uint256 oceanBal = IERC20(ocean).balanceOf(msg.sender);
        deposit(oceanBal, _lock, _stakeAddress);
    }

    /**
     * Locks all ocean tokens, stored on contract, into veOcean
     */
    function _lockOcean() internal {
        uint256 oceanBalance = IERC20(ocean).balanceOf(address(this));
        if (oceanBalance > 0) {
            IERC20(ocean).safeTransfer(staker, oceanBalance);
        }

        //increase ammount
        uint256 oceanBalanceStaker = IERC20(ocean).balanceOf(staker);
        if (oceanBalanceStaker == 0) {
            return;
        }

        //increase amount
        IStaker(staker).increaseAmount(oceanBalanceStaker);

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

        //increase time too if over 2 week buffer
        if (unlockInWeeks.sub(unlockTime) > 2) {
            unlockTime = unlockInWeeks;
            IStaker(staker).increaseTime(unlockAt);
        }
    }
}
