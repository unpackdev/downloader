// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: research@pitch.foundation

import "./ITokenMinter.sol";
import "./IVoteEscrow.sol";
import "./IStaker.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract FXSDepositor is OwnableUpgradeable, UUPSUpgradeable {
    // use SafeERC20 to secure interactions with staking and reward token
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Constants
    uint256 private constant MAXTIME = 4 * 364 * 86400; // 4 Years
    uint256 private constant WEEK = 7 * 86400; // Week
    uint256 public constant FEE_DENOMINATOR = 10000;

    // State variables
    uint256 public lockIncentive; // Incentive to users who spend gas to lock FXS
    uint256 public incentiveFXS;
    uint256 public unlockTime;

    // Addresses
    address public staker; // Voter Proxy
    address public minter; // pitchFXS Token
    address public FXS;
    address public veFXS;

    /* ========== INITIALIZER FUNCTION ========== */ 
    function initialize(address _staker, address _minter, address _FXS, address _veFXS) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        lockIncentive = 0;
        incentiveFXS = 0;
        staker = _staker;
        minter = _minter;
        FXS = _FXS;
        veFXS = _veFXS;
    }

    /* ========== OWNER FUNCTIONS ========== */
    // --- Update Addresses --- //
    function setFXS(address _FXS) external onlyOwner {
        FXS = _FXS;
    }

    function setVeFXS(address _veFXS) external onlyOwner {
        veFXS = _veFXS;
    }
    // --- End Update Addresses --- //

    /**
     * @notice Set the lock incentive, can only be called by contract owner.
     * @param _lockIncentive New incentive for users who lock FXS.
     */
    function setFees(uint256 _lockIncentive) external onlyOwner {
        if (_lockIncentive >= 0 && _lockIncentive <= 30) {
            lockIncentive = _lockIncentive;
            emit FeesChanged(_lockIncentive);
        }
    }

    /**
     * @notice Set the initial veFXS lock, can only be called by contract owner.
     */
    function initialLock() external onlyOwner {
        uint256 veFXSBalance = IERC20Upgradeable(veFXS).balanceOf(staker);
        uint256 locked = IVoteEscrow(veFXS).locked(staker);

        if (veFXSBalance == 0 || veFXSBalance == locked) {
            uint256 unlockAt = block.timestamp + MAXTIME;
            uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

            // Release old lock on FXS if it exists
            IStaker(staker).release(address(staker));

            // Create a new lock 
            uint256 stakerFXSBalance = IERC20Upgradeable(FXS).balanceOf(staker);
            IStaker(staker).createLock(stakerFXSBalance, unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}
    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== LOCKING FUNCTIONS ========== */
    function _lockFXS() internal {
        // Get FXS balance of depositor
        uint256 fxsBalance = IERC20Upgradeable(FXS).balanceOf(address(this));

        // If there's a positive FXS balance, send it to the staker
        if (fxsBalance > 0) {
            IERC20Upgradeable(FXS).safeTransfer(staker, fxsBalance);
            emit TokenLocked(msg.sender, fxsBalance);
        }

        // Increase the balance of the staker
        uint256 fxsBalanceStaker = IERC20Upgradeable(FXS).balanceOf(staker);
        if (fxsBalanceStaker == 0) {
            return;
        }
        
        IStaker(staker).increaseAmount(fxsBalanceStaker);

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

        // Increase time if over 1 week buffer
        if (unlockInWeeks - unlockTime >= 1) {
            IStaker(staker).increaseTime(unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    function lockFXS() external {
        _lockFXS();

        // Mint incentives for locking FXS
        if (incentiveFXS > 0) {
            ITokenMinter(minter).mint(msg.sender, incentiveFXS);
            emit IncentiveReceived(msg.sender, incentiveFXS);
            incentiveFXS = 0;
        }
    }
    /* ========== END LOCKING FUNCTIONS ========== */

    /* ========== DEPOSIT FUNCTIONS ========== */
    function deposit(uint256 _amount, bool _lock) public {
        // Make sure we're depositing an amount > 0
        require(_amount > 0, "FXS Depositor : Cannot deposit 0");

        if (_lock) {
            // Lock FXS immediately, transfer to staker
            IERC20Upgradeable(FXS).safeTransferFrom(msg.sender, staker, _amount);
            _lockFXS();

            if (incentiveFXS > 0) {
                // Add the incentive tokens here to be staked together
                _amount += incentiveFXS;
                emit IncentiveReceived(msg.sender, incentiveFXS);
                incentiveFXS = 0;
            }
        } else {
            // Move tokens to this address to defer lock
            IERC20Upgradeable(FXS).safeTransferFrom(msg.sender, address(this), _amount);

            // Defer lock cost to another user
            if (lockIncentive > 0) {
                uint256 callIncentive = (_amount * lockIncentive) / FEE_DENOMINATOR;
                _amount -= callIncentive;

                // Add to a pool for lock caller
                incentiveFXS += callIncentive;
            }
        }

        // Mint token for sender
        ITokenMinter(minter).mint(msg.sender, _amount);

        // Emit event
        emit Deposited(msg.sender, _amount, _lock);
    }

    function depositAll(bool _lock) external {
        uint256 fxsBalance = IERC20Upgradeable(FXS).balanceOf(msg.sender);
        deposit(fxsBalance, _lock);
    }

    /* ========== END DEPOSIT FUNCTIONS ========== */

    /* ========== EVENTS ========== */
    event Deposited(address indexed caller, uint256 amount, bool lock);
    event TokenLocked(address indexed caller, uint256 amount);
    event IncentiveReceived(address indexed caller, uint256 amount);
    event FeesChanged(uint256 newFee);
}
