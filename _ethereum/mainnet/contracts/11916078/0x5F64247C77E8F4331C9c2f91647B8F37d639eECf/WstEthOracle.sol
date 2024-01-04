// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./SafeMath.sol";

import "./IERC20.sol";
import "./IOracle.sol";
import "./IChainLinkAggregator.sol";
import "./IWstETH.sol";
import "./ICurve.sol";


contract WstEthOracle is IOracle {
    using SafeMath for uint256;

    IChainLinkAggregator public chainLinkEthAggregator = IChainLinkAggregator(
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );

    address public stETHCrvPoolAddress = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;

    address public wstETHAddress = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    uint256 public chainlinkEthScalar;

    constructor() public {
        chainlinkEthScalar = uint256(18 - chainLinkEthAggregator.decimals());
    }

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        // get stETH per wstETH
        uint256 stEthPerWstEth = IWstETH(wstETHAddress).stEthPerToken();

        // Get amount of USD per stETH to check against safety margin
        uint256 ethPerStEth = ICurve(stETHCrvPoolAddress).get_dy(1, 0, 10 ** 18);
        require(
            ethPerStEth >= 8 * 10 ** 17,
            "The amount of ETH per stETH cannot be less than 0.8 ETH"
        );

        // If the amount of ETH per stETH is higher than 1 ETH, limit it to 1
        if (ethPerStEth > 10 ** 18) {
            ethPerStEth = 10 ** 18;
        }

        // get amount of eth per one wstETH
        uint256 ethPerWstEth = ethPerStEth.mul(stEthPerWstEth).div(10 ** 18);

        // get price in USD
        uint256 usdPerEth = uint256(chainLinkEthAggregator.latestAnswer()).mul(10 ** chainlinkEthScalar);

        uint256 usdPerWstEth = usdPerEth.mul(ethPerWstEth).div(10 ** 18);

        require(
            usdPerWstEth > 0,
            "WstEthOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: usdPerWstEth
        });
    }
}
