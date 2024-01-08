// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IAlphaStaking {
    event SetWorker(address worker);
    event Stake(address owner, uint256 share, uint256 amount);
    event Unbond(address owner, uint256 unbondTime, uint256 unbondShare);
    event Withdraw(address owner, uint256 withdrawShare, uint256 withdrawAmount);
    event CancelUnbond(address owner, uint256 unbondTime, uint256 unbondShare);
    event Reward(address worker, uint256 rewardAmount);
    event Extract(address governor, uint256 extractAmount);

    struct Data {
        uint256 status;
        uint256 share;
        uint256 unbondTime;
        uint256 unbondShare;
    }

    // solhint-disable-next-line func-name-mixedcase
    function STATUS_READY() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function STATUS_UNBONDING() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function UNBONDING_DURATION() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function WITHDRAW_DURATION() external view returns (uint256);

    function alpha() external view returns (address);

    function getStakeValue(address user) external view returns (uint256);

    function totalAlpha() external view returns (uint256);

    function totalShare() external view returns (uint256);

    function stake(uint256 amount) external;

    function unbond(uint256 share) external;

    function withdraw() external;

    function users(address user) external view returns (Data calldata);
}
