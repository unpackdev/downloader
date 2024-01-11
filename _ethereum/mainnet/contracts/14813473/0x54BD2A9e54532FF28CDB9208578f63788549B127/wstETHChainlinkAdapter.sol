// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "SafeInt256.sol";
import "ChainlinkAdapter.sol";
import "IwstETH.sol";

contract wstETHChainlinkAdapter is ChainlinkAdapter {
    using SafeInt256 for int256;

    int256 public constant wstDecimals = 10**18;
    IwstETH public immutable wstETH;

    constructor (
        AggregatorV2V3Interface baseToUSDOracle_,
        AggregatorV2V3Interface quoteToUSDOracle_,
        string memory description_,
        IwstETH wstETH_
    ) ChainlinkAdapter(baseToUSDOracle_, quoteToUSDOracle_, description_) {
        wstETH = wstETH_;
    }

    /// @notice stEthPerToken gets the amount of stETH for a one wstETH
    function _convertAnswer(int256 answer) internal override view returns (int256) {
        return answer.mul(SafeInt256.toInt(wstETH.stEthPerToken())).div(wstDecimals);
    }
}
