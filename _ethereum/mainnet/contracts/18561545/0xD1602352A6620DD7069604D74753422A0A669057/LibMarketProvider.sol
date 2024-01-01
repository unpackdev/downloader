// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibMarketProvider {
    /// @dev function that will get APY fee of the loan amount in borrowed
    function getAPYFee(
        uint256 loanAmount,
        uint256 apyFee,
        uint256 loanterminDays
    ) internal pure returns (uint256) {
        return ((loanAmount * apyFee * loanterminDays) / 10000 / 365);
    }
}
