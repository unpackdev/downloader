// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyQuoteV2 {
    /// @notice Let user to calculate policy cost in DAI, access: ANY
    function getQuoteEpochs(
        uint256 _epochsNumber,
        uint256 _tokens,
        address _policyBookAddr
    ) external view returns (uint256);

    /// @notice Let user to calculate policy cost in DAI, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _tokens is number of tokens to cover
    /// @param _policyBookAddr is address of policy book
    /// @return _daiTokens is amount of DAI policy costs
    function getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        address _policyBookAddr
    ) external view returns (uint256 _daiTokens);
}
