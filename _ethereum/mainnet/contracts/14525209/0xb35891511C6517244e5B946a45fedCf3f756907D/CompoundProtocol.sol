// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";

import "./ICERC20.sol";
import "./IComptroller.sol";
import "./DecimalsConverter.sol";

import "./IContractsRegistry.sol";
import "./IReinsurancePool.sol";
import "./IDefiProtocol.sol";

import "./AbstractDependant.sol";
import "./Globals.sol";

contract CompoundProtocol is IDefiProtocol, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 internal constant ERRCODE_OK = 0;
    // 1 * 10 ^ (18 + underlyingDecimals(6) - cTokenDecimals(8) + 2 (convert from underlyingDecimals to cTokenDecimals)
    uint256 internal constant COMPOUND_EXCHANGE_RATE_PRECISION = 10**18;

    uint256 public totalDeposit;
    uint256 public totalRewards;
    uint256 public stblDecimals;

    ERC20 public override stablecoin;
    ICERC20 public cToken;
    IComptroller comptroller;
    IReinsurancePool public reinsurancePool;

    address public yieldGeneratorAddress;
    address public capitalPoolAddress;

    //new state post v2
    /// @notice setting or update of totalStableValue after call _totalValue() function
    uint256 public totalStableValue;

    modifier onlyYieldGenerator() {
        require(_msgSender() == yieldGeneratorAddress, "CP: Not a yield generator contract");
        _;
    }

    function __CompoundProtocol_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stablecoin = ERC20(_contractsRegistry.getUSDTContract());
        cToken = ICERC20(_contractsRegistry.getCompoundCTokenContract());
        comptroller = IComptroller(_contractsRegistry.getCompoundComptrollerContract());
        yieldGeneratorAddress = _contractsRegistry.getYieldGeneratorContract();
        reinsurancePool = IReinsurancePool(_contractsRegistry.getReinsurancePoolContract());
        capitalPoolAddress = _contractsRegistry.getCapitalPoolContract();
        stblDecimals = stablecoin.decimals();
    }

    /// @notice deposit an amount in Compound defi protocol
    /// @param amount uint256 the amount of stable coin will deposit
    function deposit(uint256 amount) external override onlyYieldGenerator {
        // Approve `amount` stablecoin to cToken
        stablecoin.safeApprove(address(cToken), 0);
        stablecoin.safeApprove(address(cToken), amount);

        // Deposit `amount` stablecoin to cToken
        uint256 res = cToken.mint(amount);
        if (res == ERRCODE_OK) {
            totalDeposit = totalDeposit.add(amount);
        }
    }

    function withdraw(uint256 amountInUnderlying)
        external
        override
        onlyYieldGenerator
        returns (uint256 actualAmountWithdrawn)
    {
        if (totalDeposit >= amountInUnderlying) {
            // Withdraw `amountInUnderlying` stablecoin from cToken
            // Transfer `amountInUnderlying` stablecoin to capital pool
            uint256 res = cToken.redeemUnderlying(amountInUnderlying);
            if (res == ERRCODE_OK) {
                stablecoin.safeTransfer(capitalPoolAddress, amountInUnderlying);

                actualAmountWithdrawn = amountInUnderlying;

                totalDeposit = totalDeposit.sub(actualAmountWithdrawn);
            }
        }
    }

    function claimRewards() external override onlyYieldGenerator {
        uint256 _totalStblValue = _totalValue();

        if (_totalStblValue > totalDeposit) {
            uint256 _accumaltedAmount = _totalStblValue.sub(totalDeposit);

            uint256 res = cToken.redeemUnderlying(_accumaltedAmount);

            if (res == ERRCODE_OK) {
                stablecoin.safeTransfer(capitalPoolAddress, _accumaltedAmount);
                reinsurancePool.addInterestFromDefiProtocols(_accumaltedAmount);

                // get comp reward on top of farming and send it to reinsurance pool
                comptroller.claimComp(address(this));

                ERC20 comp = ERC20(comptroller.getCompAddress());
                uint256 compBalance = comp.balanceOf(address(this));
                if (compBalance > 0) {
                    comp.safeTransfer(address(reinsurancePool), compBalance);
                }

                totalRewards = totalRewards.add(_accumaltedAmount);
            }
        }
    }

    function totalValue() external view override returns (uint256) {
        return totalStableValue;
    }

    function setRewards(address newValue) external override onlyYieldGenerator {}

    function _totalValue() internal returns (uint256) {
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        // Amount of stablecoin units that 1 unit of cToken can be exchanged for, scaled by 10^18
        uint256 cTokenPrice = cToken.exchangeRateCurrent();

        uint256 _totalStableValue =
            cTokenBalance.mul(cTokenPrice).div(COMPOUND_EXCHANGE_RATE_PRECISION);

        totalStableValue = _totalStableValue;

        return _totalStableValue;
    }

    function getOneDayGain() external view override returns (uint256) {
        uint256 rate = cToken.supplyRatePerBlock().mul(BLOCKS_PER_DAY).mul(PRECISION);

        return rate.div(10**18);
    }

    function updateTotalValue() external override onlyYieldGenerator returns (uint256) {
        return _totalValue();
    }

    function updateTotalDeposit(uint256 _lostAmount) external override onlyYieldGenerator {
        totalDeposit = totalDeposit.sub(_lostAmount);
    }
}
