// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyQuote {
    /// @notice Let user to calculate policy cost in DAI, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _tokens is a number of tokens to cover
    /// @param _totalCoverTokens is a number of covered tokens
    /// @param _totalLiquidity is a liquidity amount
    /// @return amount of DAI policy costs
    function getQuotePredefined(
        uint256 _durationSeconds,
        uint256 _tokens,
        uint256 _totalCoverTokens,
        uint256 _totalLiquidity,
        bool _safePolicyBook
    ) external view returns (uint256);

    /// @notice Let user to calculate policy cost in DAI, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _tokens is number of tokens to cover
    /// @param _policyBookAddr is address of policy book
    /// @return amount of DAI policy costs
    function getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        address _policyBookAddr
    ) external view returns (uint256);
}
