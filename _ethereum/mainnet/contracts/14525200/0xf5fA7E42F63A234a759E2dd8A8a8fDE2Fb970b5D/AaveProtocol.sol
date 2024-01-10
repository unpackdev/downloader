// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";

import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./DataTypes.sol";

import "./IContractsRegistry.sol";
import "./IReinsurancePool.sol";
import "./IDefiProtocol.sol";

import "./AbstractDependant.sol";
import "./Globals.sol";

contract AaveProtocol is IDefiProtocol, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;
    using SafeMath for uint128;
    using Math for uint128;

    uint256 public totalDeposit;
    uint256 public totalRewards;
    ERC20 public override stablecoin;
    ERC20 public aToken;

    ILendingPoolAddressesProvider public provider;
    IReinsurancePool public reinsurancePool;
    address public yieldGeneratorAddress;
    address public capitalPoolAddress;

    modifier onlyYieldGenerator() {
        require(_msgSender() == yieldGeneratorAddress, "AP: Not a yield generator contract");
        _;
    }

    function __AaveProtocol_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stablecoin = ERC20(_contractsRegistry.getUSDTContract());
        aToken = ERC20(_contractsRegistry.getAaveATokenContract());
        yieldGeneratorAddress = _contractsRegistry.getYieldGeneratorContract();
        reinsurancePool = IReinsurancePool(_contractsRegistry.getReinsurancePoolContract());
        capitalPoolAddress = _contractsRegistry.getCapitalPoolContract();
        provider = ILendingPoolAddressesProvider(
            _contractsRegistry.getAaveLendPoolAddressProvdierContract()
        );
    }

    /// @notice deposit an amount in defi protocol
    /// @param amount uint256 the amount of stable coin will deposit
    function deposit(uint256 amount) external override onlyYieldGenerator {
        ILendingPool lendingPool = _getLendingPool();

        // Approve `amount` stablecoin to lendingPool
        stablecoin.safeApprove(address(lendingPool), 0);
        stablecoin.safeApprove(address(lendingPool), amount);

        // Deposit `amount` stablecoin to lendingPool
        lendingPool.deposit(address(stablecoin), amount, address(this), 0);

        // disable use the deposited asset as collateral at first deposit
        if (totalDeposit == 0) {
            _disableUseAssetAsCollateral();
        }

        totalDeposit = totalDeposit.add(amount);
    }

    /// @notice withdraw an amount from Aave defi protocol
    /// @param amountInUnderlying uint256 the amount of underlying token to withdraw the deposited stable coin
    function withdraw(uint256 amountInUnderlying)
        external
        override
        onlyYieldGenerator
        returns (uint256 actualAmountWithdrawn)
    {
        if (totalDeposit >= amountInUnderlying) {
            ILendingPool lendingPool = _getLendingPool();

            // Redeem `amountInUnderlying` aToken, since 1 aToken = 1 stablecoin
            // Transfer `amountInUnderlying` stablecoin to capital pool
            actualAmountWithdrawn = lendingPool.withdraw(
                address(stablecoin),
                amountInUnderlying,
                capitalPoolAddress
            );

            totalDeposit = totalDeposit.sub(actualAmountWithdrawn);
        }
    }

    /// @notice claim rewards and send it to reinsurance pool
    function claimRewards() external override onlyYieldGenerator {
        ILendingPool lendingPool = _getLendingPool();

        uint256 _totalStblValue = _totalValue();

        if (_totalStblValue > totalDeposit) {
            uint256 _accumaltedAmount = _totalStblValue.sub(totalDeposit);

            uint256 _amountInUnderlying =
                lendingPool.withdraw(address(stablecoin), _accumaltedAmount, capitalPoolAddress);

            reinsurancePool.addInterestFromDefiProtocols(_accumaltedAmount);

            totalRewards = totalRewards.add(_amountInUnderlying);
        }
    }

    /// @return uint256 The total value locked in the defi protocol, in terms of the underlying stablecoin
    function totalValue() external view override returns (uint256) {
        return _totalValue();
    }

    function setRewards(address newValue) external override onlyYieldGenerator {}

    /// @notice get current lending pool address of Aave
    function _getLendingPool() internal view returns (ILendingPool) {
        return ILendingPool(provider.getLendingPool());
    }

    function _totalValue() internal view returns (uint256) {
        ILendingPool lendingPool = _getLendingPool();

        uint256 aTokenBalance = aToken.balanceOf(address(this));

        uint256 accumlatedUserBalance =
            aTokenBalance.mul(lendingPool.getReserveNormalizedIncome(address(stablecoin))).div(
                10**27
            );

        return accumlatedUserBalance;
    }

    /// @notice isable use the deposited asset as collateral at first deposit
    function _disableUseAssetAsCollateral() internal {
        ILendingPool lendingPool = _getLendingPool();

        lendingPool.setUserUseReserveAsCollateral(address(stablecoin), false);
    }

    function getOneDayGain() external view override returns (uint256) {
        DataTypes.ReserveData memory reserveData =
            ILendingPool(provider.getLendingPool()).getReserveData(address(stablecoin));

        return reserveData.currentLiquidityRate.div(365).div(100);
    }

    function updateTotalValue() external override onlyYieldGenerator returns (uint256) {}

    function updateTotalDeposit(uint256 _lostAmount) external override onlyYieldGenerator {
        totalDeposit = totalDeposit.sub(_lostAmount);
    }
}
