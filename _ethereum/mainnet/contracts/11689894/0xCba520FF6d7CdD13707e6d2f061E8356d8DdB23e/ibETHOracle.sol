// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

import "./IOracle.sol";
import "./IChainLinkAggregator.sol";

import "./IibETH.sol";

contract ibETHOracle is IOracle {

    using SafeMath for uint256;

    IERC20 public ibETH = IERC20(0x67B66C99D3Eb37Fa76Aa3Ed1ff33E8e39F0b9c7A);

    IChainLinkAggregator public chainLinkEthAggregator = IChainLinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    uint256 public chainlinkEthScalar;

    uint256 constant public CHAIN_LINK_DECIMALS = 10**8;

    constructor() public {
        chainlinkEthScalar = uint256(18 - chainLinkEthAggregator.decimals());
    }

     function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {

        uint256 amountOfEthPerIBETH = IibETH(address(ibETH)).totalETH().mul(10 ** 18).div(
            ibETH.totalSupply()
        );

        uint256 priceOfEth = uint256(
            chainLinkEthAggregator.latestAnswer()
        ).mul(10 ** chainlinkEthScalar);

        uint256 result = amountOfEthPerIBETH.mul(priceOfEth).div(10 ** 18);

        require(
            result > 0,
            "ibETHOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: result
        });

    }

}
