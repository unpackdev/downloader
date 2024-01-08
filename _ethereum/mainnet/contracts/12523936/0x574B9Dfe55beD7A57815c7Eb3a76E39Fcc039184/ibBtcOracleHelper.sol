// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IChainLinkOracle.sol";
import "./IXToken.sol";

contract ibBtcOracleHelper is IChainLinkOracle {
    IChainLinkOracle constant public btcFeed = IChainLinkOracle(0x8Aa3932790b33C7Cc751231161Ae5221af058D12);
    IXToken constant public ibBTC = IXToken(0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F);

    function latestAnswer() external override view returns (uint256 answer) {
        uint256 btcPrice = btcFeed.latestAnswer();
        answer = btcPrice * ibBTC.pricePerShare();
    }
}