pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./BasicMaths.sol";

library Price {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using BasicMaths for bool;

    uint256 private constant E18 = 1e18;

    function lsTokenPrice(uint256 totalSupply, uint256 liquidityPool)
        internal
        pure
        returns (uint256)
    {
        if (totalSupply == 0 || liquidityPool == 0) {
            return E18;
        }

        return liquidityPool.mul(E18) / totalSupply;
    }

    function lsTokenByPoolToken(
        uint256 totalSupply,
        uint256 liquidityPool,
        uint256 poolToken
    ) internal pure returns (uint256) {
        return poolToken.mul(E18) / lsTokenPrice(totalSupply, liquidityPool);
    }

    function poolTokenByLsTokenWithDebt(
        uint256 totalSupply,
        uint256 bondsLeft,
        uint256 liquidityPool,
        uint256 lsToken
    ) internal pure returns (uint256) {
        require(liquidityPool > bondsLeft, "debt scale over pool assets");
        return lsToken.mul(lsTokenPrice(totalSupply, liquidityPool.sub(bondsLeft))) / E18;
    }

    function calLsAvgPrice(
        uint256 lsAvgPrice,
        uint256 lsTotalSupply,
        uint256 amount,
        uint256 lsTokenAmount
    ) internal pure returns (uint256) {
        return lsAvgPrice.mul(lsTotalSupply).add(amount.mul(E18)) / lsTotalSupply.add(lsTokenAmount);
    }

    function divPrice(uint256 value, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return value.mul(E18) / price;
    }

    function mulPrice(uint256 size, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return size.mul(price) / E18;
    }

    function calFundingFee(uint256 rebaseSize, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return mulPrice(rebaseSize.div(E18), price);
    }

    function calDeviationPrice(uint256 deviation, uint256 price, uint8 direction)
        internal
        pure
        returns (uint256)
    {
        if (direction == 1) {
            return price.add(price.mul(deviation) / E18);
        }

        return price.sub(price.mul(deviation) / E18);
    }

    function calRepay(int256 debtChange)
        internal
        pure
        returns (uint256)
    {
        return debtChange < 0 ? uint256(-debtChange): 0;
    }
}
