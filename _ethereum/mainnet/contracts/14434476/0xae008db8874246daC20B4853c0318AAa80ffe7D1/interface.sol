// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IStakeManagerProxy {
    function getValidatorContract(uint256 validatorId)
        external
        view
        returns (address);
}

interface IValidatorShareProxy {
    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external;

    function restake() external;

    function withdrawRewards() external;

    function sellVoucher_new(uint256 _claimAmount, uint256 _maximumSharesToBurn)
        external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;
}
