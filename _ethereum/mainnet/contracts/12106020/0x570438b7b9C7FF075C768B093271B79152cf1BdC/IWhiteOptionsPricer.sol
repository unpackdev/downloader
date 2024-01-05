// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

interface IWhiteOptionsPricer {
    function getOptionPrice(
        uint256 period,
        uint256 amount,
        uint256 strike
    )
        external
        view
        returns (uint256 total);

    function getAmountToWrapFromTotal(uint total, uint period) external view returns (uint);

}
