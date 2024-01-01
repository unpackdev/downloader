// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISTBTVault {

    struct StakeInfo {
        uint256 amount;
        uint256 requestTimestamp;
        uint256 requestEpoch;
    }

    struct WithdrawInfo {
        uint256 amount;
        uint256 requestTimestamp;
        uint256 requestEpoch;
    }

    function epoch() external view returns (uint256);

    function period() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function gasthreshold() external view returns (uint256);

    function fee() external view returns (uint256);

    function feeTo() external view returns (uint256);

    function minimumRequest() external view returns (uint256);

    function withdrawLockupEpochs() external view returns (uint256);

    function total_supply_staked() external view returns (uint256);

    function total_supply_wait() external view returns (uint256);

    function total_supply_withdraw() external view returns (uint256);

    function balance_reward(address user) external view returns (int256);

    function balance_staked(address user) external view returns (uint256);

    function balance_wait(address user) external view returns (uint256);

    function balance_withdraw(address user) external view returns (uint256);

    function canWithdraw(address user) external view returns (bool);

    function earned(address user) external view returns (int256);

    function stakeRequest(address user) external view returns (StakeInfo memory);

    function withdrawRequest(address user) external view returns (WithdrawInfo memory);
}