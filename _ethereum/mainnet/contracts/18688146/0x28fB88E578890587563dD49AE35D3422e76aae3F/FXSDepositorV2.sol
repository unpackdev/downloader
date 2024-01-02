// SPDX-License-Identifier: MIT
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
import "./IVoterProxy.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract FXSDepositorV2 is OwnableUpgradeable, UUPSUpgradeable {
    // use SafeERC20 to secure interactions with staking and reward token
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error CannotBeZero();
    error NotRedeemableYet();

    // Constants
    uint256 public constant MAXTIME = 4 * 364 * 86400; // 4 Years
    uint256 public constant WEEK = 7 * 86400; // Week
    uint256 public constant FEE_DENOMINATOR = 10000;

    // State variables
    /// @notice // Incentive to users who spend gas to lock FXS
    uint256 public lockIncentive;
    uint256 public incentiveFXS;
    uint256 public unlockTime;

    // Addresses
    address public staker; // Voter Proxy
    address public minter; // pitchFXS Token
    address public fxs;
    address public veFXS;

    bool public vefxsClaimed;

    constructor() {
        _disableInitializers();
    }

    /* ========== OWNER FUNCTIONS ========== */
    // --- Update Addresses --- //
    function setFXS(address _fxs) external onlyOwner {
        fxs = _fxs;
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
            IVoterProxy(staker).release(address(staker));

            // Create a new lock
            uint256 stakerFXSBalance = IERC20Upgradeable(fxs).balanceOf(staker);

            IVoterProxy(staker).createLock(stakerFXSBalance, unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== LOCKING FUNCTIONS ========== */
    function _lockFXS() internal {
        // Get FXS balance of depositor
        uint256 fxsBalance = IERC20Upgradeable(fxs).balanceOf(address(this));

        // If there's a positive FXS balance, send it to the staker
        if (fxsBalance > 0) {
            IERC20Upgradeable(fxs).safeTransfer(staker, fxsBalance);
            emit TokenLocked(msg.sender, fxsBalance);
        }

        // Increase the balance of the staker
        uint256 fxsBalanceStaker = IERC20Upgradeable(fxs).balanceOf(staker);
        if (fxsBalanceStaker == 0) {
            return;
        }

        IVoterProxy(staker).increaseAmount(fxsBalanceStaker);

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

        // Increase time if over 1 week buffer
        if (unlockInWeeks - unlockTime >= 1) {
            IVoterProxy(staker).increaseTime(unlockAt);
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
        // require(_amount > 0, "FXS Depositor : Cannot deposit 0");
        if (_amount <= 0) revert CannotBeZero();

        if (_lock) {
            // Lock FXS immediately, transfer to staker
            IERC20Upgradeable(fxs).safeTransferFrom(msg.sender, staker, _amount);
            _lockFXS();

            if (incentiveFXS > 0) {
                // Add the incentive tokens here to be staked together
                _amount += incentiveFXS;
                emit IncentiveReceived(msg.sender, incentiveFXS);
                incentiveFXS = 0;
            }
        } else {
            // Move tokens to this address to defer lock
            IERC20Upgradeable(fxs).safeTransferFrom(msg.sender, address(this), _amount);

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
        uint256 fxsBalance = IERC20Upgradeable(fxs).balanceOf(msg.sender);
        deposit(fxsBalance, _lock);
    }

    /// @notice Redeem an amount of pitchFXS for FXS
    /// @dev The underlying FXS MUST be unlocked or it will revert.
    /// @param _amount Amount of pitchFXS to redeem.
    function redeem(uint256 _amount) external {
        // Once the voter proxy's FXS is unlocked, claim it, pulling the balance of FXS into this contract.
        if (!vefxsClaimed) {
            // If not claimed, check if lock has either ended or been released
            if (
                IVoteEscrow(veFXS).locked__end(staker) < block.timestamp 
                || 
                IVoteEscrow(veFXS).emergencyUnlockActive()
            ) {
                // Ascertain the current balance of FXS held here
                uint256 fxsBalanceBefore = IERC20Upgradeable(fxs).balanceOf(address(this));

                // If available to claim FXS from veFXS, trigger voter proxy to do so.
                IVoterProxy(staker).release(address(this));

                // Check that fxs balance has increased
                require(IERC20Upgradeable(fxs).balanceOf(address(this)) > fxsBalanceBefore, "!fxsClaimed");

                // Update vefxsClaimed to true so this logic does not get executed again
                vefxsClaimed = true;
            }
        }

        // check that there is enough fxs on hand to meet the redemption, which should always revert before the unlock & claiming of FXS
        if (IERC20Upgradeable(fxs).balanceOf(address(this)) < _amount) revert NotRedeemableYet();

        // Burn pitchFXS, as it was minted 1:1 with FXS
        ITokenMinter(minter).burn(msg.sender, _amount);

        // Transfer the redeemed FXS to user
        IERC20Upgradeable(fxs).safeTransfer(msg.sender, _amount);
    }

    /* ========== END DEPOSIT FUNCTIONS ========== */

    /* ========== EVENTS ========== */
    event Deposited(address indexed caller, uint256 amount, bool lock);
    event TokenLocked(address indexed caller, uint256 amount);
    event IncentiveReceived(address indexed caller, uint256 amount);
    event FeesChanged(uint256 newFee);
}
