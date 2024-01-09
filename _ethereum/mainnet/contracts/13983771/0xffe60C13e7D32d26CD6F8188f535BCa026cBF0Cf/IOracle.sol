// contracts/TestToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

interface IOracle {
    function getRate(
        IERC20 srcToken,
        IERC20 dstToken,
        bool useWrappers
    ) external view returns (uint256 weightedRate);
}
