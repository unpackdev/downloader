// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov (az@unit.xyz).
*/
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./ChainlinkedKeydonixOracleMainAssetAbstract.sol";
import "./ChainlinkedKeydonixOraclePoolTokenAbstract.sol";


/**
 * @title ChainlinkedKeydonixOraclePoolToken
 * @author Unit Protocol: Artem Zakharov (az@unit.xyz), Alexander Ponomorev (@bcngod)
 * @dev Calculates the USD price of Uniswap LP tokens
 **/
contract ChainlinkedKeydonixOraclePoolToken is ChainlinkedKeydonixOraclePoolTokenAbstract {
    using SafeMath for uint;

    constructor(address _uniswapOracleMainAsset) public {
        uniswapOracleMainAsset = ChainlinkedKeydonixOracleMainAssetAbstract(_uniswapOracleMainAsset);
    }

    /**
     * @notice This function implements flashloan-resistant logic to determine USD price of Uniswap LP tokens
     * @notice Block number of merkle proof must be in range [MIN_BLOCKS_BACK ... MAX_BLOCKS_BACK] (see ChainlinkedKeydonixOracleMainAsset)
     * @notice Pair must be registered on Uniswap
     * @param asset The LP token address
     * @param amount Amount of asset
     * @param proofData The proof data of underlying token price
     * @return Q112 encoded price of asset in USD
     **/
    function assetToUsd(
        address asset,
        uint amount,
        UniswapOracle.ProofData memory proofData
    )
        public
        override
        view
        returns (uint)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(asset);
        address underlyingAsset;
        if (pair.token0() == uniswapOracleMainAsset.WETH()) {
            underlyingAsset = pair.token1();
        } else if (pair.token1() == uniswapOracleMainAsset.WETH()) {
            underlyingAsset = pair.token0();
        } else {
            revert("Unit Protocol: NOT_REGISTERED_PAIR");
        }

        uint eAvg = uniswapOracleMainAsset.assetToEth(underlyingAsset, 1, proofData); // average price of 1 token in ETH

        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint aPool; // current asset pool
        uint ePool; // current WETH pool
        if (pair.token0() == underlyingAsset) {
            aPool = uint(_reserve0);
            ePool = uint(_reserve1);
        } else {
            aPool = uint(_reserve1);
            ePool = uint(_reserve0);
        }

        uint eCurr = ePool.mul(Q112).div(aPool); // current price of 1 token in WETH
        uint ePoolCalc; // calculated WETH pool

        if (eCurr < eAvg) {
            // flashloan buying WETH
            uint sqrtd = ePool.mul((ePool).mul(9).add(
                aPool.mul(3988000).mul(eAvg).div(Q112)
            ));
            uint eChange = sqrt(sqrtd).sub(ePool.mul(1997)).div(2000);
            ePoolCalc = ePool.add(eChange);
        } else {
            // flashloan selling WETH
            uint a = aPool.mul(eAvg);
            uint b = a.mul(9).div(Q112);
            uint c = ePool.mul(3988000);
            uint sqRoot = sqrt(a.div(Q112).mul(b.add(c)));
            uint d = a.mul(3).div(Q112);
            uint eChange = ePool.sub(d.add(sqRoot).div(2000));
            ePoolCalc = ePool.sub(eChange);
        }

        uint num = ePoolCalc.mul(2).mul(amount).mul(Q112);
        uint priceInEth = num.div(pair.totalSupply());

        return uniswapOracleMainAsset.ethToUsd(priceInEth);
    }

    function sqrt(uint x) internal pure returns (uint y) {
        if (x > 3) {
            uint z = x / 2 + 1;
            y = x;
            while (z < y) {
                y = z;
                z = (x / z + z) / 2;
            }
        } else if (x != 0) {
            y = 1;
        }
    }
}
