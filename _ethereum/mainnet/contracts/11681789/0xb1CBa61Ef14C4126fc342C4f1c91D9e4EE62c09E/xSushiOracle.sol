// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

import "./IOracle.sol";
import "./IChainLinkAggregator.sol";

contract xSushiOracle is IOracle {

    using SafeMath for uint256;

    IERC20 public sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IERC20 public xsushi = IERC20(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);

    IChainLinkAggregator public chainLinkEthAggregator = IChainLinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IChainLinkAggregator public chainLinkTokenAggregator = IChainLinkAggregator(0xe572CeF69f43c2E488b33924AF04BDacE19079cf);

    uint256 public chainlinkTokenScalar;
    uint256 public chainlinkEthScalar;

    uint256 constant public CHAIN_LINK_DECIMALS = 10**8;

    constructor() public {
        chainlinkEthScalar = uint256(18 - chainLinkEthAggregator.decimals());
        chainlinkTokenScalar = uint256(18 - chainLinkTokenAggregator.decimals());
    }

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        uint256 amountOfSushiPerXSushi = sushi.balanceOf(
            address(xsushi)
        ).mul(10 ** 18).div(xsushi.totalSupply());

        // Some result in x decimal places
        uint256 priceInEth = uint256(
            chainLinkTokenAggregator.latestAnswer()
        ).mul(10 ** chainlinkTokenScalar);

        uint256 priceOfEth = uint256(
            chainLinkEthAggregator.latestAnswer()
        ).mul(10 ** chainlinkEthScalar);

        uint256 result = amountOfSushiPerXSushi.mul(priceInEth).div(10 ** 18);

        result = result.mul(priceOfEth).div(10 ** 18);

        require(
            result > 0,
            "XSushiOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: result
        });
    }

}
