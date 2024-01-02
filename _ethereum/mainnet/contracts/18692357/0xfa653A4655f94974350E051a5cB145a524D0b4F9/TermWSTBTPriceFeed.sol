// SPDX-License-Identifier: AGPL-3.0
// See: https://github.com/Matrixdock-STBT/STBT-contracts/blob/main/contracts/WSTBT.sol
pragma solidity ^0.8.18;

import "./AggregatorV3Interface.sol";

import "./IERC20.sol";
import "./SafeCast.sol";

import "./IWstbt.sol";

/**
 * @title MatrixDock WSTBT Oracle
 * @notice Get WSTBT price via their contracts
 */
contract TermWSTBTPriceFeed is AggregatorV3Interface {
    using SafeCast for uint256;

    IWstbt public immutable wstbt;
    AggregatorV3Interface immutable stbtPORAggregator;
    
    constructor(address wstbtAddress, address stbtPORAddress) {
        require(
            wstbtAddress != address(0),
            "wstbtAddress cannot be zero"
        );

        require(
            stbtPORAddress != address(0),
            "stbtPORAddress cannot be zero"
        );
        wstbt = IWstbt(wstbtAddress);
        stbtPORAggregator = AggregatorV3Interface(stbtPORAddress);
    }

    function description() external pure override returns (string memory) {
        return "WSTBT Price Feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function getRoundData(
        uint80 /* roundId */
    )
        external
        pure
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        
        int256 stbtPerWstbt = int256(wstbt.getStbtByWstbt(1e18));
        (, int256 stbtPOR, , ,) = stbtPORAggregator.latestRoundData();
        IERC20 stbtToken = IERC20(wstbt.stbtAddress());
        int256 reserveBackingPerSTBT = (stbtPOR * 1e18) / int256(stbtToken.totalSupply());


        int256 wstbtPrice;
        if (reserveBackingPerSTBT <= 1e18) {
            wstbtPrice = (reserveBackingPerSTBT * stbtPerWstbt) / 1e18;
        } else {
            wstbtPrice = stbtPerWstbt;
        }

        return (0, wstbtPrice, 0, 0, 0);
    }
}
