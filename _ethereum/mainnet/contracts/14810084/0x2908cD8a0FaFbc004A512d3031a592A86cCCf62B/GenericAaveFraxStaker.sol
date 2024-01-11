// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./IFraxUnifiedFarmTemplate.sol";
import "./GenericAaveUpgradeable.sol";

/// @title GenericAaveFraxStaker
/// @author  Angle Core Team
/// @notice `GenericAaveUpgradeable` implementation for FRAX where aFRAX obtained from Aave are staked on a FRAX contract
/// to earn FXS incentives
contract GenericAaveFraxStaker is GenericAaveUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    // ============================= Protocol Addresses ============================

    AggregatorV3Interface private constant oracleFXS =
        AggregatorV3Interface(0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f);
    IFraxUnifiedFarmTemplate private constant aFraxStakingContract =
        IFraxUnifiedFarmTemplate(0x02577b426F223A6B4f2351315A19ecD6F357d65c);
    uint256 private constant FRAX_IDX = 0;

    // ================================ Variables ==================================

    /// @notice Hash representing the position on Frax staker
    bytes32 public kekId;
    /// @notice Used to track the current liquidity (staked + interests) from Aave
    uint256 public lastAaveReserveNormalizedIncome;
    /// @notice Tracks the amount of FRAX controlled by the protocol and lent as aFRAX on Frax staking contract
    /// This quantity increases due to the Aave native yield
    uint256 private lastLiquidity;
    /// @notice Last time a staker has been created
    uint256 public lastCreatedStake;

    // ================================ Parameters =================================

    /// @notice Minimum amount of aFRAX to stake
    uint256 private constant minStakingAmount = 1000 * 1e18; // 1000 aFrax
    /// @notice Staking duration
    uint256 public stakingPeriod;

    // ==================================== Errors =================================

    error NoLockedLiquidity();
    error TooSmallStakingPeriod();

    // ============================= Constructor ===================================

    /// @notice Wrapper built on top of the `initializeAave` method to initialize the contract
    /// @param _stakingPeriod Amount of time aFRAX must remain staked
    /// @dev This function also initialized some FRAX related parameters like the staking period
    function initialize(
        address _strategy,
        string memory name,
        bool _isIncentivised,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList,
        uint256 _stakingPeriod
    ) external {
        initializeAave(_strategy, name, _isIncentivised, governorList, guardian, keeperList);
        if (_stakingPeriod < aFraxStakingContract.lock_time_min()) revert TooSmallStakingPeriod();
        stakingPeriod = _stakingPeriod;
        lastAaveReserveNormalizedIncome = _lendingPool.getReserveNormalizedIncome(address(want));
    }

    // =========================== External Function ===============================

    /// @notice Permisionless function to claim rewards, reward tokens are directly sent to the contract and keeper/governance
    /// can handle them via a `sweep` or a `sellRewards` call
    function claimRewardsExternal() external returns (uint256[] memory) {
        return aFraxStakingContract.getReward(address(this));
    }

    // =========================== Governance Functions ============================

    /// @notice Updates the staking period on the aFRAX staking contract
    function setLockTime(uint256 _stakingPeriod) external onlyRole(GUARDIAN_ROLE) {
        if (_stakingPeriod < aFraxStakingContract.lock_time_min()) revert TooSmallStakingPeriod();
        stakingPeriod = _stakingPeriod;
    }

    /// @notice Sets a proxy on the staking contract to obtain a delegation from an address with a boost
    /// @dev Contract can have a multiplier on its FXS rewards if granted by someone with boosting power
    /// @dev Can only be called after Frax governance called `aFraxStakingContract.toggleValidVeFXSProxy(proxy)`
    /// and proxy called `aFraxStakingContract.proxyToggleStaker(address(this))`
    function setProxyBoost(address proxy) external onlyRole(GUARDIAN_ROLE) {
        aFraxStakingContract.stakerSetVeFXSProxy(proxy);
    }

    // ============================ Virtual Functions ==============================

    /// @notice Implementation of the `_stake` function to stake aFRAX in the FRAX staking contract
    /// @dev If there is an existent locker already on Frax staking contract (keckId != null), then this function adds to it
    /// otherwise (if it's the first time we deposit or if last action was a withdraw) we need to create a new locker
    /// @dev Currently there is no additional reward to stake more than the minimum period as there is no multiplier
    function _stake(uint256 amount) internal override returns (uint256 stakedAmount) {
        uint256 pastReserveNormalizedIncome = lastAaveReserveNormalizedIncome;
        uint256 newReserveNormalizedIncome = _lendingPool.getReserveNormalizedIncome(address(want));
        lastAaveReserveNormalizedIncome = newReserveNormalizedIncome;

        IERC20(address(_aToken)).safeApprove(address(aFraxStakingContract), amount);
        if (kekId == bytes32(0)) {
            lastLiquidity = amount;
            lastCreatedStake = block.timestamp;
            kekId = aFraxStakingContract.stakeLocked(amount, stakingPeriod);
        } else {
            // Updating the `lastLiquidity` value
            lastLiquidity = (lastLiquidity * newReserveNormalizedIncome) / pastReserveNormalizedIncome + amount;
            aFraxStakingContract.lockAdditional(kekId, amount);
        }
        stakedAmount = amount;
    }

    /// @notice Implementation of the `_unstake` function
    /// @dev If the minimum staking period is not finished, the function will revert
    /// @dev This implementation assumes that there cannot any loss when staking on FRAX
    function _unstake(uint256 amount) internal override returns (uint256 freedAmount) {
        if (kekId == bytes32(0)) return 0;

        lastAaveReserveNormalizedIncome = _lendingPool.getReserveNormalizedIncome(address(want));
        freedAmount = aFraxStakingContract.withdrawLocked(kekId, address(this));

        if (amount + minStakingAmount < freedAmount) {
            // If too much has been withdrawn, we must create back a locker
            lastCreatedStake = block.timestamp;
            uint256 amountFRAXControlled = freedAmount - amount;
            lastLiquidity = amountFRAXControlled;
            IERC20(address(_aToken)).safeApprove(address(aFraxStakingContract), amountFRAXControlled);
            kekId = aFraxStakingContract.stakeLocked(amountFRAXControlled, stakingPeriod);

            // We need to round down the `freedAmount` value because values can be rounded down when transfering aTokens
            // and we may stake slightly less than desired: to play it safe in all cases and avoid multiple calls, we
            // systematically round down
            freedAmount = amount - 1;
        } else {
            lastLiquidity = 0;
            lastCreatedStake = 0;
            delete kekId;
        }
    }

    /// @notice Get current staked Frax balance (counting interest received since last update)
    function _stakedBalance() internal view override returns (uint256 amount) {
        uint256 reserveNormalizedIncome = _lendingPool.getReserveNormalizedIncome(address(want));
        return (lastLiquidity * reserveNormalizedIncome) / lastAaveReserveNormalizedIncome;
    }

    /// @notice Get stakingAPR after staking an additional `amount`
    /// @param amount Virtual amount to be staked
    function _stakingApr(uint256 amount) internal view override returns (uint256 apr) {
        // These computations are made possible only because there can only be one staker in the contract
        (uint256 oldCombinedWeight, uint256 newVefxsMultiplier, uint256 newCombinedWeight) = aFraxStakingContract
            .calcCurCombinedWeight(address(this));

        uint256 newBalance;
        // If we didn't stake anything and we don't have anything to give, then stakingApr can only be 0
        if (lastLiquidity == 0 && amount == 0) return 0;
        // If we didn't stake we need an extra info on the multiplier per staking period
        // otherwise we reverse engineer the function
        else if (lastLiquidity == 0) {
            newBalance = amount;
            newCombinedWeight =
                (newBalance * (aFraxStakingContract.lockMultiplier(stakingPeriod) + newVefxsMultiplier)) /
                1 ether;
        } else {
            newBalance = (_stakedBalance() + amount);
            newCombinedWeight = (newBalance * newCombinedWeight) / lastLiquidity;
        }

        // If we arrive up until here the `totalCombinedWeight` can only be non null
        uint256 totalCombinedWeight = aFraxStakingContract.totalCombinedWeight() +
            newCombinedWeight -
            oldCombinedWeight;

        uint256 rewardRate = (newCombinedWeight * aFraxStakingContract.rewardRates(FRAX_IDX)) / totalCombinedWeight;

        // APRs are in 1e18 and a 5% penalty on the FXS price is taken to avoid overestimations
        apr = (_estimatedFXSToWant(rewardRate * _SECONDS_IN_YEAR) * 9500 * 1 ether) / 10000 / newBalance;
    }

    // ============================ Internal Functions =============================

    /// @notice Estimates the amount of `want` we will get out by swapping it for FXS
    /// @param amount Amount of FXS we want to exchange (in base 18)
    /// @return swappedAmount Amount of `want` we are getting but in a global base 18
    /// @dev Uses Chainlink spot price
    /// @dev This implementation assumes that 1 FRAX = 1 USD, as it does not do any FRAX -> USD conversion
    function _estimatedFXSToWant(uint256 amount) internal view returns (uint256) {
        (, int256 fxsPriceUSD, , , ) = oracleFXS.latestRoundData();
        // fxsPriceUSD is in base 8
        return (uint256(fxsPriceUSD) * amount) / 1e8;
    }
}
