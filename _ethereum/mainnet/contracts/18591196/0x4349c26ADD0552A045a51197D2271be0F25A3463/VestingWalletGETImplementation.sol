// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./ILockedRevenueDistributionToken.sol";

import "./Initializable.sol";

/**
 * @title VestingWalletGETImplementation
 * @dev This contract handles the vesting of ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract VestingWalletGETImplementation is Context, Initializable {
    // events
    event AdminAccessBurned();
    event EtherSaved(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);
    event AdminWithdraw(address indexed token, uint256 amount);
    event NothingToClaim();
    event UnlockedTokensStaked(uint256 amountUnlocked, uint256 amountStaked);

    address private beneficiary_;

    uint256 private constant cooldownPeriod_ = 30 days;
    uint256 private lastReleased_;
    mapping(address => uint256) private _erc20Released;
    ILockedRevenueDistributionToken public constant stakingContract_ =
        ILockedRevenueDistributionToken(0x3e49E9C890Cd5B015A18ed76E7A4093f569f1A04);
    IERC20 public constant lockToken_ = IERC20(0x8a854288a5976036A725879164Ca3e91d30c6A1B);
    uint64 private constant duration_ = 365 days;

    address private constant admin_ = address(0xF989c1694A735b10c2Dac36078fA929cd4235AF5);

    address private administeredBy_;

    bool public adminAccessBurned;

    function initializeVesting(address _beneficiary, uint256 _startMoment) external initializer {
        beneficiary_ = _beneficiary;
        administeredBy_ = admin_;
        lastReleased_ = _startMoment;
    }

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor() {}

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return beneficiary_;
    }

    /**
     * @dev Getter for the admin address.
     */
    function administeredBy() public view virtual returns (address) {
        return administeredBy_;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return lastReleased_;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return duration_;
    }

    /**
     * @dev Duration of the cooldown period
     */
    function cooldownPeriod() public view virtual returns (uint256) {
        return cooldownPeriod_;
    }

    /**
     * @dev Timestamp of the last token release
     */
    function lastRelease() public view virtual returns (uint256) {
        return lastReleased_;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     * @dev Release the native token (ether) that was sent to this wallt by accident
     */
    function salvageEthereum() public virtual {
        require(msg.sender == beneficiary(), "VestingWallet: not beneficiary");
        emit EtherSaved(address(this).balance);
        Address.sendValue(payable(beneficiary()), address(this).balance);
    }

    function burnAdminAccess() public virtual {
        require(msg.sender == administeredBy_, "VestingWallet: not administered by admin");
        require(!adminAccessBurned, "VestingWallet: admin access already burned");
        administeredBy_ = address(0);
        adminAccessBurned = true;
        emit AdminAccessBurned();
    }

    /**
     * @notice Withdraw vested tokens by admin
     * @param _tokenAddress address of the token to withdraw
     * @param _withdrawAmount amount of token to withdraw
     */
    function withdrawTokensByAdmin(address _tokenAddress, uint256 _withdrawAmount) external {
        require(msg.sender == administeredBy_, "VestingWallet: not administered by admin");
        require(!adminAccessBurned, "VestingWallet: admin access burned");
        SafeERC20.safeTransfer(IERC20(_tokenAddress), administeredBy_, _withdrawAmount);
        emit AdminWithdraw(_tokenAddress, _withdrawAmount);
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(address token) public view virtual returns (uint256) {
        uint256 vested_ = vestedAmount(token, uint64(block.timestamp));
        if (vested_ != 0) {
            return vested_ - released(token);
        } else {
            return 0;
        }
    }

    function releaseLockToken() public virtual returns (uint256 amountStakedTokensReleased_) {
        return release(address(lockToken_));
    }

    /**
     * @dev Release the tokens that have already vested.
     * Emits a {ERC20Released} event.
     */
    function release(address token) public virtual returns (uint256 amountStakedTokensReleased_) {
        uint256 amount = releasable(token);
        if (amount != 0) {
            lastReleased_ = block.timestamp;
        } else {
            emit NothingToClaim();
            return 0;
        }
        _erc20Released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeApprove(IERC20(token), address(stakingContract_), amount);
        uint256 amountStakedTokens_ = stakingContract_.deposit(amount, beneficiary(), 0);
        emit UnlockedTokensStaked(amount, amountStakedTokens_);
        return amountStakedTokens_;
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp <= start()) {
            return 0;
        } else if ((lastReleased_ + cooldownPeriod_) > timestamp) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}
