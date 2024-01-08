// SPDX-License-Identifier: AGPLv3

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./BaseStrategy.sol";

import "./IUni.sol";
import "./IHarvest.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Math.sol";

/// @notice Harvest finance stablecoin strategy
///     Deposits and stakes stablecoins into Harvest finance - this strategy
///     generates yield through the underlying protocol + the selling of farm tokens
///     ########################################
///     Strategy breakdown
///     ########################################
///
///     Want: stablecoin 
///     Additional tokens: fToken, Farm
///     Exposures: 
///         Protocol: Harvest Finance, Compound, Idle finance
///         stablecoins: want
///
///     Strategy logic:
///         Vault => Loans out stablecoin to strategy
///             strategy => invest stablecoin into harvset finance fVault
///                      <= get fToken in return
///             strategy => stakes fToken in fToken staking contract
///                      <= get fToken stake shares in return
///                      <= get Farm tokens in return for staking
///
///         Harvest: Report back gains/losses to vault, sells Farm tokens:
contract StrategyHarvestStable is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address[] public farmPath;
    IHarvest public harvestStrat;
    IStake public harvestStake;
    IERC20 public farm =IERC20(address(0xa0246c9032bC3A600820415aE600c6388619A14D));
    IERC20 public weth = IERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
   
    constructor(address _vault, address _harvestStake) public BaseStrategy(_vault) {
        profitFactor = 1000;
        debtThreshold = 1_000_000 *1e18;
        harvestStake = IStake(_harvestStake);
        address _harvestStrat = harvestStake.lpToken();
        harvestStrat = IHarvest(_harvestStrat);
        require(address(want) == harvestStrat.underlying(), "Wrong farm");
        farmPath = new address[](3);
        farmPath[0] = address(farm);
        farmPath[1] = address(weth);
        farmPath[2] = address(want);

        want.safeApprove(_harvestStrat, type(uint256).max);
        IERC20(address(harvestStrat)).safeApprove(_harvestStake, type(uint256).max);
        farm.safeApprove(uniswapRouter, uint(-1));
    }

    function name() external override view returns (string memory) {
        return string(abi.encodePacked("StrategyHarvest", harvestStrat.symbol()));
    }

    /// @notice Get the total assets of this strategy
    /// @return Total assets in want this strategy has invested
    function estimatedTotalAssets() public override view returns (uint256) {
        return want.balanceOf(address(this))
            .add(convertToUnderlying(harvestStake.balanceOf(address(this))));
    }

    /// @notice Convert fTokens to want
    /// @param amountOfTokens Amount to convert
    function convertToUnderlying(uint256 amountOfTokens) public view returns (uint256) {
        return amountOfTokens > 0 ? amountOfTokens
            .mul(harvestStrat.getPricePerFullShare())
            .div(10**harvestStrat.decimals()) : 0;
    }

    /// @notice Check if it's worth harvesting the strategy
    /// @param callCost The keeper's estimated cast cost to call `harvest()`
    /// @return true True if gains outweigh cost of calling harvest
    function harvestTrigger(uint256 callCost) public override view returns (bool) {
        uint256 wantCallCost = ethToWant(callCost);
        uint estimatedFarm = harvestStake.earned(address(this));
        if (estimatedFarm > 0) {
            wantCallCost = wantCallCost.sub(farmToWant(estimatedFarm));
        }
        return super.harvestTrigger(wantCallCost);
    }

    /// @notice Convert want to fTokens
    /// @param amountOfUnderlying Amount to convert
    function convertFromUnderlying(uint256 amountOfUnderlying) public view returns (uint256 balance){
        if (amountOfUnderlying == 0) {
            balance = 0;
        } else {
            balance = amountOfUnderlying
                .mul(10**harvestStrat.decimals())
                .div(harvestStrat.getPricePerFullShare());
        }
    }

    /// @notice Expected returns from strategy (gains from protocols and tokens)
    function expectedReturn() public view returns (uint256)
    {
        uint256 estimateAssets = estimatedTotalAssets();
        uint estimatedFarm = harvestStake.earned(address(this));
        if (estimatedFarm > 0) {
            estimateAssets = estimateAssets.add(farmToWant(estimatedFarm));
        }
        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets - debt;
        }
    }

    /// @notice Claim any available Farm rewards
    function claimFarm() internal {
        harvestStake.getReward();

        IUni(uniswapRouter).swapExactTokensForTokens(
            farm.balanceOf(address(this)),
            uint256(0),
            farmPath,
            address(this),
            now
        );
    }

    /// @notice This strategy doesnt realise profit outside of APY from the vault.
    ///     This method is only used to pull out debt if debt ratio has changed 
    /// @param _debtOutstanding debt to pay back.
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _debtPayment = _debtOutstanding;
        uint256 lentAssets = convertToUnderlying(harvestStake.balanceOf(address(this)));
        if (harvestStake.earned(address(this)) > 0 ) {
            claimFarm();
        }
        uint256 looseAssets = want.balanceOf(address(this));
        uint256 total = looseAssets.add(lentAssets);
        if (lentAssets == 0) {
            // No position to harvest or profit to report
            if (_debtPayment > looseAssets) {
                // We can only return looseAssets
                _debtPayment = looseAssets;
            }
            return (_profit, _loss, _debtPayment);
        }
        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (total > debt) {
            _profit = total - debt;
            uint256 amountToFree = _profit.add(_debtPayment);
            if (amountToFree > 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));
                // If we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _profit, _debtPayment);
                    }
                }
            }
        } else {
            // Serious - A loss should never happen but if it does lets record it accurately
            _loss = debt - total;
            uint256 amountToFree = _debtPayment;
            if (amountToFree > 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));
                if (newLoose < amountToFree) {
                    _debtPayment = newLoose;
                }
            }
        }
    }

    /// @notice Used to invest any assets sent from the vault during report
    /// @param _debtOutstanding Should always be 0 at this point
    function adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 _toInvest = want.balanceOf(address(this));
        if (_toInvest > 0 ) {
            harvestStrat.deposit(_toInvest);
            harvestStake.stake(harvestStrat.balanceOf(address(this)));
        }
    }

    /// @notice Withdraw amount of want from fStake/fToken 
    /// @param _amount Expected amount to withdraw
    function _withdrawSome(uint256 _amount) internal returns (uint256) {

        uint256 amountInFtokens = convertFromUnderlying(_amount);
        uint256 stakeBalance = harvestStake.balanceOf(address(this));

        uint256 balanceBefore = want.balanceOf(address(this));

        if(amountInFtokens < 2){
            return 0;
        }
        if (amountInFtokens > stakeBalance) {
            // Can't withdraw more than we own
            amountInFtokens = stakeBalance;
        }
        // Not state changing but OK because of previous call
        uint256 liquidityInFTokens = harvestStrat.balanceOf(address(harvestStake));

        if (liquidityInFTokens > 2) {
            if (amountInFtokens <= liquidityInFTokens) {
                // We can take all
                harvestStake.withdraw(amountInFtokens);
                harvestStrat.withdraw(amountInFtokens);
            } else {
                // Take all we can
                harvestStake.withdraw(liquidityInFTokens);
                harvestStrat.withdraw(liquidityInFTokens);
            }
        }
        uint256 newBalance = want.balanceOf(address(this));
        return newBalance.sub(balanceBefore);
    }

    /// @notice Used when emergency stop has been called to empty out strategy
    /// @param _amountNeeded Expected amount to withdraw
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        _loss; // Should not be able to make a loss here
        uint256 looseAssets = want.balanceOf(address(this));
        if(looseAssets < _amountNeeded){
            _withdrawSome(_amountNeeded - looseAssets);
        }
        _liquidatedAmount = Math.min(_amountNeeded, want.balanceOf(address(this)));
    }

    /// @notice Convert farm tokens to want
    /// @param amount Amount to convert
    function farmToWant(uint256 amount) internal view returns (uint256) {
        uint256[] memory amounts = IUni(uniswapRouter).getAmountsOut(amount, farmPath);
        return amounts[amounts.length - 1];
    }

    /// @notice Convert ETH to want, used for harvest trigger
    /// @param amount Amount to convert
    function ethToWant(uint256 amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(want);

        uint256[] memory amounts = IUni(uniswapRouter).getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }

    function prepareMigration(address _newStrategy) internal override {
        uint256 remFarm = harvestStake.earned(address(this));
        if (remFarm > 0) {
            claimFarm();
        }

        harvestStake.exit();
        IERC20(address(harvestStrat)).safeTransfer(_newStrategy, harvestStrat.balanceOf(address(this)));
    }

    function protectedTokens()
        internal
        override
        view
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
          protected[0] = address(harvestStrat);
          protected[1] = address(harvestStake);
          return protected;
    }
}
