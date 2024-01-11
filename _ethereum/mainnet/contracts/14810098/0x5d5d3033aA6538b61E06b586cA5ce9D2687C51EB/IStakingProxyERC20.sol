// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IStakingProxyERC20 {
    //create a new locked state of _secs timelength
    function stakeLocked(uint256 _liquidity, uint256 _secs) external;

    //add to a current lock
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;

    //withdraw a staked position
    function withdrawLocked(bytes32 _kek_id) external;

    //helper function to combine earned tokens on staking contract and any tokens that are on this vault
    function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned);

    /*
    claim flow:
        claim rewards directly to the vault
        calculate fees to send to fee deposit
        send fxs to booster for fees
        get reward list of tokens that were received
        send all remaining tokens to owner

    A slightly less gas intensive approach could be to send rewards directly to booster and have it sort everything out.
    However that makes the logic a bit more complex as well as runs a few future proofing risks
    */
    function getReward() external;

    //get reward with claim option.
    //_claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
    //there are tokens on this vault for cases such as withdraw() also calling claim.
    //can also be used to rescue tokens on the vault
    function getReward(bool _claim) external;
}
