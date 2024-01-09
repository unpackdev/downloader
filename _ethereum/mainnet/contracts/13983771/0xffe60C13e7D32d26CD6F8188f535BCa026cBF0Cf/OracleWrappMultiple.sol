// contracts/TestToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IOracle.sol";
import "ERC20.sol";

contract OracleWrappMultiple {
    function getRates(
        IERC20[] memory srcTokens,
        IERC20 dstToken,
        bool useWrappers,
        IOracle oracle
    ) external view returns (uint256[] memory weightedRate) {
        uint256 srcLength = srcTokens.length;
        uint256[] memory rates = new uint256[](srcLength);

        for (uint256 i = 0; i < srcLength; i++) {
            rates[i] = oracle.getRate(srcTokens[i], dstToken, useWrappers);
        }

        return rates;
    }
}
