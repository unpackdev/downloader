// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./FarmingLib.sol";
import "./SafeTransferLib.sol";

/// @title ERC20FarmingPool
/// @author Modified from (https://github.com/1inch/farming/tree/master/contracts)
abstract contract ERC20FarmingPool is Ownable, ERC20 {
    // =============================================================
    //                           LIBRARIES
    // =============================================================

    using FarmingLib for FarmingLib.Info;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event RewardUpdated(uint256 reward, uint256 duration);
    event DistributorChanged(address newDistributor);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error SameStakingAndRewardsTokens();
    error ZeroStakingTokenAddress();
    error ZeroRewardsTokenAddress();
    error AccessDenied();
    error InsufficientFunds();
    error MaxBalanceExceeded();
    error NotDistributor();
    error ZeroDistributorAddress();

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint256 internal constant _MAX_BALANCE = 1e32;

    // =============================================================
    //                           IMMUTABLES
    // =============================================================

    address public immutable stakingToken;
    address public immutable rewardsToken;

    // =============================================================
    //                           STORAGE
    // =============================================================

    FarmingLib.Data private _farm;
    address internal _distributor;

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    modifier onlyDistributor() {
        if (msg.sender != _distributor) revert NotDistributor();
        _;
    }

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    constructor(address owner_, address stakingToken_, address rewardsToken_) {
        if (stakingToken_ == rewardsToken_) revert SameStakingAndRewardsTokens();
        if (stakingToken_ == address(0)) revert ZeroStakingTokenAddress();
        if (rewardsToken_ == address(0)) revert ZeroRewardsTokenAddress();

        _initializeOwner(owner_);

        stakingToken = stakingToken_;
        rewardsToken = rewardsToken_;
    }

    // =============================================================
    //                           EXTERNAL FUNCTIONS
    // =============================================================

    /**
     * @notice Sets the entity that can manage the farming
     */
    function setDistributor(address distributor_) public virtual onlyOwner {
        if (distributor_ == address(0)) revert ZeroDistributorAddress();
        emit DistributorChanged(distributor_);
        _distributor = distributor_;
    }

    /**
     * @notice Returns the entity that can manage the farming
     */
    function distributor() public view virtual returns (address) {
        return _distributor;
    }

    /**
     * @notice Returns the farming info
     */
    function farmInfo() public view returns (FarmAccounting.Info memory) {
        return _farm.farmInfo;
    }

    /**
     * @notice Allows the distributor to start farming
     */
    function startFarming(uint256 amount, uint256 period) public virtual onlyDistributor {
        uint256 reward = _makeInfo().startFarming(amount, period);
        emit RewardUpdated(reward, period);

        SafeTransferLib.safeTransferFrom(rewardsToken, _distributor, address(this), amount);
    }

    /**
     * @notice Allows the distributor to stop farming
     */
    function stopFarming() public virtual onlyDistributor {
        uint256 leftover = _makeInfo().stopFarming();
        emit RewardUpdated(0, 0);
        if (leftover > 0) {
            SafeTransferLib.safeTransfer(rewardsToken, _distributor, leftover);
        }
    }

    /**
     * @notice Returns the amount of rewards that can be claimed by the account
     */
    function farmed(address account) public view virtual returns (uint256) {
        return _makeInfo().farmed(account, balanceOf(account));
    }

    /**
     * @notice Allows the account to deposit the staking token
     */
    function deposit(uint256 amount) public virtual {
        _mint(msg.sender, amount);
        if (balanceOf(msg.sender) > _MAX_BALANCE) revert MaxBalanceExceeded();
        SafeTransferLib.safeTransferFrom(stakingToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Allows the account to withdraw the staking token
     */
    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);
        SafeTransferLib.safeTransfer(stakingToken, msg.sender, amount);
    }

    /**
     * @notice Allows the account to claim the rewards
     */
    function claim() public virtual {
        uint256 amount = _makeInfo().claim(msg.sender, balanceOf(msg.sender));
        if (amount > 0) {
            SafeTransferLib.safeTransfer(rewardsToken, msg.sender, amount);
        }
    }

    /**
     * @notice Allows the account to exit the farming, simultaneously withdrawing and claiming rewards
     */
    function exit() public virtual {
        withdraw(balanceOf(msg.sender));
        claim();
    }

    /**
     * @notice Allows the distributor to rescue funds
     */
    function rescueFunds(address token, uint256 amount) public virtual onlyDistributor {
        if (token == address(0)) {
            SafeTransferLib.forceSafeTransferETH(_distributor, amount);
        } else {
            if (token == stakingToken) {
                if (ERC20(stakingToken).balanceOf(address(this)) < totalSupply() + amount) revert InsufficientFunds();
            } else if (token == rewardsToken) {
                if (ERC20(rewardsToken).balanceOf(address(this)) < _farm.farmInfo.balance + amount) {
                    revert InsufficientFunds();
                }
            }

            SafeTransferLib.safeTransfer(token, _distributor, amount);
        }
    }

    // =============================================================
    //                           INTERNAL FUNCTIONS
    // =============================================================

    function _makeInfo() private view returns (FarmingLib.Info memory) {
        return FarmingLib.makeInfo(totalSupply, _farm);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (amount > 0 && from != to) {
            _makeInfo().updateBalances(from, to, amount);
        }
    }
}
