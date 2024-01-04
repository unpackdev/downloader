// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import "./IERC20.sol";

import "./IUniswapOracle.sol";
import "./ISimpleOracle.sol";
import "./IBoardroom.sol";
import "./IBasisAsset.sol";
import "./ISimpleERCFund.sol";
import "./TreasuryState.sol";

import "./ICustomERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

abstract contract TreasuryGetters is TreasuryState {
    function getReserve() public view returns (uint256) {
        return accumulatedSeigniorage;
    }

    function getStabilityFee() public view returns (uint256) {
        return stabilityFee;
    }

    function getBondOraclePrice() public view returns (uint256) {
        return _getCashPrice(bondOracle);
    }

    function getGMUOraclePrice() public view returns (uint256) {
        return ISimpleOracle(gmuOracle).getPrice();
    }

    function getArthMahaOraclePrice() public view returns (uint256) {
        return ISimpleOracle(arthMahaOracle).getPrice();
    }

    function getPercentDeviationFromTarget(uint256 price)
        public
        view
        returns (uint256)
    {
        uint256 target = getGMUOraclePrice();

        if (price > target) return price.sub(target).mul(100).div(target);
        return target.sub(price).mul(100).div(target);
    }

    function getSeigniorageOraclePrice() public view returns (uint256) {
        return _getCashPrice(seigniorageOracle);
    }

    function arthCirculatingSupply() public view returns (uint256) {
        return IERC20(cash).totalSupply().sub(accumulatedSeigniorage);
    }

    function bondCirculatingSupply() public view returns (uint256) {
        return ICustomERC20(bond).totalSupply().sub(accumulatedSeigniorage);
    }

    /**
     * Understand how much Seignorage should be minted
     */
    function estimateSeignorageToMint(uint256 price)
        public
        view
        returns (uint256)
    {
        if (price <= cashTargetPrice) return 0; // < $1.00
        uint256 percentage = getPercentDeviationFromTarget(price);

        // cap the max supply increase per epoch to only 30%
        uint256 finalPercentage =
            Math.min(percentage, maxSupplyIncreasePerEpoch);

        // take into consideration uniswap liq. if flag is on, ie how much liquidity is there in the ARTH uniswap pool
        uint256 toMint = arthCirculatingSupply().mul(finalPercentage).div(100);

        // if we are below the expansion price limit; only pay back bond holders if we are within the right price range
        // < $1.05
        if (price <= getExpansionLimitPrice()) {
            return Math.min(toMint, bondCirculatingSupply());
        }

        return toMint;
    }

    function estimateBondsToIssue(uint256 price) public view returns (uint256) {
        uint256 bondPurchasePrice = getBondPurchasePrice();

        // check if we are in contract mode.
        if (price > bondPurchasePrice) return 0; // <= $0.95?

        // in contraction mode -> issue bonds.
        // set a limit to how many bonds are there.

        uint256 percentage = getPercentDeviationFromTarget(price);

        // understand how much % deviation do we have from target price
        // if target price is 2.5$ and we are at 2$; then percentage should be 20%
        // cap the bonds to be issed; we don't want too many
        uint256 finalPercentage = Math.min(percentage, maxDebtIncreasePerEpoch);

        // accordingly set the new conversion limit to be that % from the
        // current circulating supply of ARTH and if uniswap enabled then uniswap liquidity.
        return
            arthCirculatingSupply()
                .mul(finalPercentage)
                .div(100)
                .mul(getCashSupplyInLiquidity())
                .div(100);
    }

    function getBondRedemtionPrice() public view returns (uint256) {
        return cashTargetPrice; // 1$
    }

    function getExpansionLimitPrice() public view returns (uint256) {
        return cashTargetPrice.mul(safetyRegion.add(100)).div(100); // 1.05$
    }

    function getBondPurchasePrice() public view returns (uint256) {
        return cashTargetPrice.mul(uint256(100).sub(safetyRegion)).div(100); // 0.95$
    }

    function getCashSupplyInLiquidity() public view returns (uint256) {
        // check if enabled or not
        if (!considerUniswapLiquidity) return uint256(100);

        address uniswapFactory = IUniswapV2Router02(uniswapRouter).factory();
        address uniswapLiquidityPair =
            IUniswapV2Factory(uniswapFactory).getPair(cash, dai);

        // Get the liquidity of cash locked in uniswap pair.
        uint256 uniswapLiquidityPairCashBalance =
            ICustomERC20(cash).balanceOf(uniswapLiquidityPair);

        // Get the liquidity percent.
        return
            uniswapLiquidityPairCashBalance.mul(100).div(
                ICustomERC20(cash).totalSupply()
            );
    }

    function get1hourEpoch() public view returns (uint256) {
        return Epoch(bondOracle).getLastEpoch();
    }

    function _getCashPrice(address oracle) internal view returns (uint256) {
        try IUniswapOracle(oracle).consult(cash, 1e18) returns (uint256 price) {
            return price;
        } catch {
            revert('Treasury: failed to consult cash price from the oracle');
        }
    }
}
