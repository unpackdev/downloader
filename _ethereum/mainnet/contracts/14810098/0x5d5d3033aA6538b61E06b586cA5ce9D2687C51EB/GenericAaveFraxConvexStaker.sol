// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./IFraxUnifiedFarmTemplate.sol";
import "./IBoosterFrax.sol";
import "./IPoolRegistryFrax.sol";
import "./IFeeRegistryFrax.sol";
import "./IStakingProxyERC20.sol";

import "./GenericAaveUpgradeable.sol";

/// @title GenericAaveFraxConvexStaker
/// @author  Angle Core Team
/// @notice `GenericAaveUpgradeable` implementation for FRAX where aFRAX obtained from Aave are staked on a Convex
/// contract to earn FXS incentives with max boost
contract GenericAaveFraxConvexStaker is GenericAaveUpgradeable {
    using SafeERC20 for IERC20;

    // ============================= Protocols Addresses ============================

    AggregatorV3Interface private constant oracleFXS =
        AggregatorV3Interface(0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f);
    IBoosterFrax private constant booster = IBoosterFrax(0x9cA3EC5f627ad5D92498Fd1b006b35577760ba9A);
    IPoolRegistryFrax private constant poolRegistry = IPoolRegistryFrax(0x41a5881c17185383e19Df6FA4EC158a6F4851A69);
    IFeeRegistryFrax private constant feeRegistry = IFeeRegistryFrax(0xC9aCB83ADa68413a6Aa57007BC720EE2E2b3C46D);
    uint256 private constant convexPid = 2;

    IFraxUnifiedFarmTemplate private constant aFraxStakingContract =
        IFraxUnifiedFarmTemplate(0x02577b426F223A6B4f2351315A19ecD6F357d65c);
    uint256 private constant FRAX_IDX = 0;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    // ================================ Variables ==================================

    IStakingProxyERC20 public vault;
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

        // initialize the vault on convex and get the address for our personal vault
        booster.createVault(convexPid);
        vault = IStakingProxyERC20(poolRegistry.vaultMap(convexPid, address(this)));
    }

    // =========================== External Function ===============================

    /// @notice Can be called before `claimRewardsExternal` to check the available rewards to be claimed
    function earned() external view returns (address[] memory tokenAddresses, uint256[] memory totalEarned) {
        return vault.earned();
    }

    /// @notice Permisionless function to claim rewards, reward tokens are directly sent to the contract and keeper/governance
    /// can handle them via a `sweep` or a `sellRewards` call
    function claimRewardsExternal() external {
        return vault.getReward(true);
    }

    // =========================== Governance Functions ============================

    /// @notice Updates the staking period on the aFRAX staking contract
    function setLockTime(uint256 _stakingPeriod) external onlyRole(GUARDIAN_ROLE) {
        if (_stakingPeriod < aFraxStakingContract.lock_time_min()) revert TooSmallStakingPeriod();
        stakingPeriod = _stakingPeriod;
    }

    // ============================ Virtual Functions ==============================

    /// @notice Implementation of the `_stake` function to stake aFRAX in the FRAX staking contract
    /// @dev If there is an existent locker already on Frax/Convex staking contract (keckId != null), then this function adds to it
    /// otherwise (if it's the first time we deposit or if last action was a withdraw) we need to create a new locker
    /// @dev Currently there is no additional reward to stake more than the minimum period as there is no multiplier
    function _stake(uint256 amount) internal override returns (uint256 stakedAmount) {
        uint256 pastReserveNormalizedIncome = lastAaveReserveNormalizedIncome;
        uint256 newReserveNormalizedIncome = _lendingPool.getReserveNormalizedIncome(address(want));
        lastAaveReserveNormalizedIncome = newReserveNormalizedIncome;

        // There may be rounding errors due to aToken transfers that do not actually transfer the amount specified
        // but an underlying balance that is corrected by an index (with function rayMul and rayDiv)
        // As such, we need to take precautions on the amount of aTokens actually staked
        amount = _roundingATokenAmount(amount, newReserveNormalizedIncome);

        _changeAllowance(IERC20(address(_aToken)), address(vault), amount);
        if (kekId == bytes32(0)) {
            lastLiquidity = amount;
            lastCreatedStake = block.timestamp;
            kekId = keccak256(abi.encodePacked(address(vault), block.timestamp, amount, uint256(0)));
            vault.stakeLocked(amount, stakingPeriod);
        } else {
            // Updating the `lastLiquidity` value
            lastLiquidity = (lastLiquidity * newReserveNormalizedIncome) / pastReserveNormalizedIncome + amount;
            vault.lockAdditional(kekId, amount);
        }
        stakedAmount = amount;
    }

    /// @notice Implementation of the `_unstake` function
    /// @dev If the minimum staking period is not finished, the function will revert
    /// @dev This implementation assumes that there cannot be any loss when staking on FRAX/Convex
    function _unstake(uint256 amount) internal override returns (uint256 freedAmount) {
        if (kekId == bytes32(0)) return 0;

        uint256 lastAaveReserveNormalizedIncome_ = _lendingPool.getReserveNormalizedIncome(address(want));
        lastAaveReserveNormalizedIncome = lastAaveReserveNormalizedIncome_;

        vault.withdrawLocked(kekId);
        freedAmount = _aToken.balanceOf(address(this));

        if (amount + minStakingAmount < freedAmount) {
            lastCreatedStake = block.timestamp;
            // If too much has been withdrawn, we must create back a locker: the amount to invest is what we have
            // minus what's to withdraw
            uint256 amountFRAXToInvest = freedAmount - amount;

            // Paying attention to potential rounding errors on FRAX
            amountFRAXToInvest = _roundingATokenAmount(amountFRAXToInvest, lastAaveReserveNormalizedIncome_);

            lastLiquidity = amountFRAXToInvest;
            _changeAllowance(IERC20(address(_aToken)), address(vault), amountFRAXToInvest);
            kekId = keccak256(abi.encodePacked(address(vault), block.timestamp, amountFRAXToInvest, uint256(0)));

            vault.stakeLocked(amountFRAXToInvest, stakingPeriod);

            uint256 postABalance = _aToken.balanceOf(address(this));
            // We are limited on withdraw from Aave by the liquidity available and our aToken balance
            freedAmount = amount > postABalance ? postABalance : amount;
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

    /// @notice Rounds an amount of aTokens to invest on FRAX/Convex to avoid errors
    function _roundingATokenAmount(uint256 amount, uint256 lastAaveReserveNormalizedIncome_)
        internal
        pure
        returns (uint256 roundedAmount)
    {
        uint256 halfIndex = lastAaveReserveNormalizedIncome_ / 2;
        roundedAmount = (amount * RAY + halfIndex) / lastAaveReserveNormalizedIncome_;
        roundedAmount = (roundedAmount * lastAaveReserveNormalizedIncome_ - halfIndex) / RAY;
    }

    /// @notice Get stakingAPR after staking an additional `amount`
    /// @param amount Virtual amount to be staked
    function _stakingApr(uint256 amount) internal view override returns (uint256 apr) {
        // These computations are made possible only because there can only be one staker in the contract
        (uint256 oldCombinedWeight, uint256 newVefxsMultiplier, uint256 newCombinedWeight) = aFraxStakingContract
            .calcCurCombinedWeight(address(vault));

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

        // Convex takes a cut of the boosted rewards
        uint256 cutConvex = feeRegistry.totalFees();
        uint256 rewardRate = (newCombinedWeight * aFraxStakingContract.rewardRates(FRAX_IDX) * (1e5 - cutConvex)) /
            totalCombinedWeight /
            1e5;

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
